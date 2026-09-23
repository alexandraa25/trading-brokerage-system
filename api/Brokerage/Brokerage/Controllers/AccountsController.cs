using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Accounts;
using Brokerage.Api.DTOs.Cash;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Security.Claims;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/accounts")]
public class AccountsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<AccountSummary>>> GetAccounts()
    {
        var query = db.Accounts.AsNoTracking();
        var customerId = GetCustomerId();

        if (!IsStaff() && customerId.HasValue)
            query = query.Where(account => account.CustomerId == customerId.Value);
        else if (!IsStaff())
            return Forbid();

        var accounts = await query
            .OrderBy(account => account.AccountNumber)
            .Select(account => new AccountSummary(
                account.AccountId,
                account.AccountNumber,
                account.Currency,
                account.Status))
            .ToListAsync();

        return Ok(accounts);
    }

    [HttpGet("{accountId:long}/cash")]
    public async Task<ActionResult<IEnumerable<CashBalance>>> GetCash(long accountId)
    {
        if (!await CanAccessAccountAsync(accountId))
            return NotFound();

        var cashAccounts = await db.CashAccounts
            .AsNoTracking()
            .Where(item => item.AccountId == accountId)
            .OrderBy(item => item.Currency)
            .Select(item => new CashBalance(
                item.CashAccountId,
                item.Currency,
                item.AvailableBalance,
                item.BlockedBalance))
            .ToListAsync();

        return Ok(cashAccounts);
    }

    [HttpPost("{accountId:long}/cash-accounts")]
    public async Task<ActionResult<CashBalance>> OpenCashAccount(long accountId, OpenCashAccountRequest request)
    {
        if (!await CanAccessAccountAsync(accountId)) return NotFound();
        var currency = request.Currency.Trim().ToUpperInvariant();
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = "SELECT COUNT(1) FROM core.Currency WHERE CurrencyCode = @currency";
        command.Parameters.Add(new SqlParameter("@currency", currency));
        await db.Database.OpenConnectionAsync();
        var exists = Convert.ToInt32(await command.ExecuteScalarAsync()) > 0;
        if (!exists) return BadRequest(new ProblemDetails { Detail = "Moneda selectată nu este disponibilă." });
        if (await db.CashAccounts.AnyAsync(item => item.AccountId == accountId && item.Currency == currency))
            return Conflict(new ProblemDetails { Detail = "Există deja un cont de numerar în această monedă." });

        var cashAccount = new CashAccount { AccountId = accountId, Currency = currency, AvailableBalance = 0, BlockedBalance = 0 };
        db.CashAccounts.Add(cashAccount);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCash), new { accountId }, new CashBalance(cashAccount.CashAccountId, cashAccount.Currency, cashAccount.AvailableBalance, cashAccount.BlockedBalance));
    }

    [HttpGet("history")]
    public async Task<ActionResult<IEnumerable<PortfolioHistoryPoint>>> GetPortfolioHistory(
        [FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var customerId = GetCustomerId();
        if (!customerId.HasValue || IsStaff()) return Forbid();

        var fromDate = (from ?? DateTime.UtcNow.Date.AddDays(-6)).Date;
        var toDate = (to ?? DateTime.UtcNow.Date).Date;
        if (toDate < fromDate || toDate.Subtract(fromDate).TotalDays > 366)
            return BadRequest(new ProblemDetails { Detail = "Perioada aleasă trebuie să fie între 1 și 366 de zile." });

        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = """
            SELECT s.SnapshotDate,
                   CAST(SUM(s.InvestedValueEur) AS DECIMAL(19,4)),
                   CAST(SUM(s.PositionsValueEur) AS DECIMAL(19,4)),
                   CAST(SUM(s.CashValueEur) AS DECIMAL(19,4)),
                   CAST(SUM(s.TotalValueEur) AS DECIMAL(19,4))
            FROM reporting.PortfolioDailySnapshot s
            INNER JOIN core.Account a ON a.AccountId = s.AccountId
            WHERE a.CustomerId = @customerId
              AND s.SnapshotDate >= @fromDate AND s.SnapshotDate <= @toDate
            GROUP BY s.SnapshotDate
            ORDER BY s.SnapshotDate;
            """;
        command.Parameters.Add(new SqlParameter("@customerId", customerId.Value));
        command.Parameters.Add(new SqlParameter("@fromDate", fromDate));
        command.Parameters.Add(new SqlParameter("@toDate", toDate));
        await db.Database.OpenConnectionAsync();
        await using var reader = await command.ExecuteReaderAsync();
        var points = new List<PortfolioHistoryPoint>();
        while (await reader.ReadAsync())
            points.Add(new PortfolioHistoryPoint(reader.GetDateTime(0), reader.GetDecimal(1), reader.GetDecimal(2), reader.GetDecimal(3), reader.GetDecimal(4)));
        return Ok(points);
    }

    [HttpGet("valuation-by-currency")]
    public async Task<ActionResult<IEnumerable<CurrencyPortfolioValue>>> GetPortfolioValueByCurrency()
    {
        var customerId = GetCustomerId();
        if (!customerId.HasValue || IsStaff()) return Forbid();

        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = """
            WITH PositionValues AS
            (
                SELECT instrument.Currency,
                       CAST(SUM(position.Quantity * position.AveragePrice) AS DECIMAL(19,4)) AS InvestedValue,
                       CAST(SUM(position.Quantity * quote.MarketPrice) AS DECIMAL(19,4)) AS PositionsValue
                FROM trading.Position position
                INNER JOIN core.Account account ON account.AccountId = position.AccountId
                INNER JOIN trading.Instrument instrument ON instrument.InstrumentId = position.InstrumentId
                OUTER APPLY (SELECT TOP 1 MarketPrice FROM trading.MarketQuote WHERE InstrumentId = position.InstrumentId ORDER BY QuoteDate DESC) quote
                WHERE account.CustomerId = @customerId AND position.Quantity > 0
                GROUP BY instrument.Currency
            ), CashValues AS
            (
                SELECT cash.Currency, CAST(SUM(cash.AvailableBalance) AS DECIMAL(19,4)) AS CashValue
                FROM core.CashAccount cash
                INNER JOIN core.Account account ON account.AccountId = cash.AccountId
                WHERE account.CustomerId = @customerId
                GROUP BY cash.Currency
            )
            SELECT COALESCE(positionValue.Currency, cashValue.Currency) AS Currency,
                   ISNULL(positionValue.InvestedValue, 0) AS InvestedValue,
                   ISNULL(positionValue.PositionsValue, 0) AS PositionsValue,
                   ISNULL(cashValue.CashValue, 0) AS CashValue,
                   ISNULL(positionValue.PositionsValue, 0) + ISNULL(cashValue.CashValue, 0) AS TotalValue,
                   ISNULL(positionValue.PositionsValue, 0) - ISNULL(positionValue.InvestedValue, 0) AS ProfitLoss
            FROM PositionValues positionValue
            FULL OUTER JOIN CashValues cashValue ON cashValue.Currency = positionValue.Currency
            ORDER BY Currency;
            """;
        command.Parameters.Add(new SqlParameter("@customerId", customerId.Value));
        await db.Database.OpenConnectionAsync();
        await using var reader = await command.ExecuteReaderAsync();
        var values = new List<CurrencyPortfolioValue>();
        while (await reader.ReadAsync())
            values.Add(new CurrencyPortfolioValue(reader.GetString(0), reader.GetDecimal(1), reader.GetDecimal(2), reader.GetDecimal(3), reader.GetDecimal(4), reader.GetDecimal(5)));
        return Ok(values);
    }

    [HttpGet("{accountId:long}/portfolio")]
    public async Task<ActionResult<IEnumerable<PortfolioPosition>>> GetPortfolio(long accountId)
    {
        if (!await CanAccessAccountAsync(accountId))
            return NotFound();

        var positions = await (
            from position in db.Positions.AsNoTracking()
            join instrument in db.Instruments.AsNoTracking()
                on position.InstrumentId equals instrument.InstrumentId
            where position.AccountId == accountId && position.Quantity > 0
            orderby instrument.Symbol
            select new PortfolioPosition(
                instrument.Symbol,
                instrument.InstrumentName,
                instrument.Currency,
                position.Quantity,
                position.AveragePrice,
                position.UpdatedAt)
        ).ToListAsync();

        return Ok(positions);
    }

    [HttpGet("{accountId:long}/valuation")]
    public async Task<ActionResult<PortfolioValuation>> GetValuation(long accountId)
    {
        if (!await CanAccessAccountAsync(accountId)) return NotFound();

        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = """
            SELECT CAST(ISNULL(SUM(p.Quantity * p.AveragePrice * ISNULL(r.MidRate, 1)), 0) AS DECIMAL(19,4)) AS InvestedValueEUR,
                   CAST(ISNULL(SUM(p.Quantity * q.MarketPrice * ISNULL(r.MidRate, 1)), 0) AS DECIMAL(19,4)) AS PositionsValueEUR,
                   CAST(ISNULL((SELECT SUM(ca.AvailableBalance * ISNULL(cashRate.MidRate, 1))
                     FROM core.CashAccount ca
                     OUTER APPLY (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = ca.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) cashRate
                     WHERE ca.AccountId = @accountId), 0) AS DECIMAL(19,4)) AS CashValueEUR,
                   CAST(ISNULL(SUM(p.Quantity * q.MarketPrice * ISNULL(r.MidRate, 1)), 0) + ISNULL((SELECT SUM(ca.AvailableBalance * ISNULL(cashRate.MidRate, 1))
                     FROM core.CashAccount ca
                     OUTER APPLY (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = ca.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) cashRate
                     WHERE ca.AccountId = @accountId), 0) AS DECIMAL(19,4)) AS TotalValueEUR,
                   CAST(MAX(q.QuoteDate) AS DATETIME2) AS ValuationDate
            FROM trading.Position p
            JOIN trading.Instrument i ON i.InstrumentId = p.InstrumentId
            OUTER APPLY (SELECT TOP 1 MarketPrice, QuoteDate FROM trading.MarketQuote WHERE InstrumentId = p.InstrumentId ORDER BY QuoteDate DESC) q
            OUTER APPLY (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = i.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) r
            WHERE p.AccountId = @accountId AND p.Quantity > 0;
            """;
        command.Parameters.Add(new SqlParameter("@accountId", accountId));
        await db.Database.OpenConnectionAsync();
        await using var reader = await command.ExecuteReaderAsync();
        await reader.ReadAsync();
        var invested = reader.GetDecimal(0); var positions = reader.GetDecimal(1); var cash = reader.GetDecimal(2); var total = reader.GetDecimal(3);
        var date = reader.IsDBNull(4) ? DateTime.UtcNow : reader.GetDateTime(4);
        var profit = total - invested;
        var percent = invested == 0 ? 0 : Math.Round(profit / invested * 100, 2);
        return Ok(new PortfolioValuation(invested, positions, cash, total, profit, percent, date, "SIMULATED_DAILY + ECB_REFERENCE"));
    }

    private async Task<bool> CanAccessAccountAsync(long accountId)
    {
        if (IsStaff())
            return await db.Accounts.AnyAsync(account => account.AccountId == accountId);

        var customerId = GetCustomerId();
        return customerId.HasValue && await db.Accounts.AnyAsync(account =>
            account.AccountId == accountId && account.CustomerId == customerId.Value);
    }

    private long? GetCustomerId() =>
        long.TryParse(User.FindFirstValue("customerId"), out var customerId)
            ? customerId
            : null;

    private bool IsStaff() => User.IsInRole("Broker")
        || User.IsInRole("ComplianceOfficer")
        || User.IsInRole("Administrator");
}

public record PortfolioHistoryPoint(DateTime SnapshotDate, decimal InvestedValueEur, decimal PositionsValueEur, decimal CashValueEur, decimal TotalValueEur);
public record CurrencyPortfolioValue(string Currency, decimal InvestedValue, decimal PositionsValue, decimal CashValue, decimal TotalValue, decimal ProfitLoss);
