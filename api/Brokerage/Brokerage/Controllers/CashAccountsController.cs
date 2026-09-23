using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Accounts;
using Brokerage.Api.DTOs.Cash;
using Brokerage.Api.DTOs.History;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Security.Claims;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/cash-accounts")]
public class CashAccountsController(BrokerageDbContext db, CustomerNotificationService notifications) : ControllerBase
{
    [HttpGet("exchange-rate")]
    public async Task<IActionResult> GetExchangeRate([FromQuery] long sourceCashAccountId, [FromQuery] long targetCashAccountId)
    {
        var accounts = await GetExchangeAccountsAsync(sourceCashAccountId, targetCashAccountId);
        if (accounts is null) return NotFound();
        var quote = await GetExchangeQuoteAsync(accounts.SourceCurrency, accounts.TargetCurrency);
        return quote is null ? BadRequest(new ProblemDetails { Detail = "Nu există curs BCE disponibil pentru monedele selectate." }) : Ok(quote);
    }

    [HttpPost("exchange")]
    public async Task<IActionResult> Exchange(CurrencyExchangeRequest request)
    {
        var accounts = await GetExchangeAccountsAsync(request.SourceCashAccountId, request.TargetCashAccountId);
        if (accounts is null) return NotFound();
        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_ConvertCash";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@SourceCashAccountId", request.SourceCashAccountId));
            command.Parameters.Add(new SqlParameter("@TargetCashAccountId", request.TargetCashAccountId));
            command.Parameters.Add(new SqlParameter("@SourceAmount", request.SourceAmount));
            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync()) return Problem("Procedura de schimb valutar nu a returnat un rezultat.");
            var result = new CurrencyExchangeResult(reader.GetInt64(0), reader.GetString(1), reader.GetString(2), reader.GetDecimal(3), reader.GetDecimal(4), reader.GetDecimal(5), reader.GetDateTime(6), reader.GetDateTime(7), reader.GetString(8));
            await reader.DisposeAsync();
            await notifications.CreateAsync(accounts.CustomerId, "CurrencyExchange", "Schimb valutar efectuat",
                $"Ai schimbat {result.SourceAmount:0.00} {result.SourceCurrency} în {result.TargetAmount:0.00} {result.TargetCurrency}, la cursul {result.ExchangeRate:0.000000}.");
            return Ok(result);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    [HttpGet("{cashAccountId:long}/transactions")]
    public async Task<ActionResult<IEnumerable<CashTransactionSummary>>> GetTransactions(
        long cashAccountId)
    {
        var cashAccount = await (
            from cash in db.CashAccounts.AsNoTracking()
            join account in db.Accounts.AsNoTracking()
                on cash.AccountId equals account.AccountId
            where cash.CashAccountId == cashAccountId
            select new { account.CustomerId }
        ).SingleOrDefaultAsync();

        if (cashAccount is null || (!IsStaff() && cashAccount.CustomerId != GetCustomerId()))
            return NotFound();

        var transactions = await db.CashTransactions
            .AsNoTracking()
            .Where(transaction => transaction.CashAccountId == cashAccountId)
            .OrderByDescending(transaction => transaction.CreatedAt)
            .Select(transaction => new CashTransactionSummary(
                transaction.CashTransactionId,
                transaction.TransactionType,
                transaction.Amount,
                transaction.Currency,
                transaction.ReferenceType,
                transaction.ReferenceId,
                transaction.Description,
                transaction.CreatedAt))
            .ToListAsync();

        return Ok(transactions);
    }

    [HttpPost("{cashAccountId:long}/deposits")]
    public async Task<ActionResult<CashBalance>> Deposit(long cashAccountId, DepositRequest request)
    {
        var cashAccount = await (
            from cash in db.CashAccounts
            join account in db.Accounts on cash.AccountId equals account.AccountId
            where cash.CashAccountId == cashAccountId
            select new { Cash = cash, account.CustomerId }
        ).SingleOrDefaultAsync();

        if (cashAccount is null || (!IsStaff() && cashAccount.CustomerId != GetCustomerId()))
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_DepositCash";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@CashAccountId", cashAccountId));
            command.Parameters.Add(new SqlParameter("@Amount", request.Amount));
            command.Parameters.Add(new SqlParameter("@Description", request.Description ?? (object)DBNull.Value));
            await command.ExecuteNonQueryAsync();

            var balance = await db.CashAccounts
                .AsNoTracking()
                .Where(item => item.CashAccountId == cashAccountId)
                .Select(item => new CashBalance(
                    item.CashAccountId,
                    item.Currency,
                    item.AvailableBalance,
                    item.BlockedBalance))
                .SingleAsync();

            await notifications.CreateAsync(cashAccount.CustomerId, "Deposit", "Depunere înregistrată",
                $"Depunerea de {request.Amount:0.00} {balance.Currency} a fost înregistrată cu succes.");

            return Ok(balance);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    [HttpPost("{cashAccountId:long}/withdrawals")]
    public async Task<ActionResult<CashBalance>> Withdraw(long cashAccountId, WithdrawalRequest request)
    {
        var cashAccount = await (
            from cash in db.CashAccounts
            join account in db.Accounts on cash.AccountId equals account.AccountId
            where cash.CashAccountId == cashAccountId
            select new { Cash = cash, account.CustomerId }
        ).SingleOrDefaultAsync();

        if (cashAccount is null || (!IsStaff() && cashAccount.CustomerId != GetCustomerId()))
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_WithdrawCash";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@CashAccountId", cashAccountId));
            command.Parameters.Add(new SqlParameter("@Amount", request.Amount));
            command.Parameters.Add(new SqlParameter("@Description", request.Description ?? (object)DBNull.Value));
            await command.ExecuteNonQueryAsync();

            var balance = await db.CashAccounts.AsNoTracking().Where(item => item.CashAccountId == cashAccountId)
                .Select(item => new CashBalance(item.CashAccountId, item.Currency, item.AvailableBalance, item.BlockedBalance)).SingleAsync();
            await notifications.CreateAsync(cashAccount.CustomerId, "Withdrawal", "Retragere înregistrată",
                $"Retragerea de {request.Amount:0.00} {balance.Currency} a fost înregistrată cu succes.");
            return Ok(balance);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    private long? GetCustomerId() =>
        long.TryParse(User.FindFirstValue("customerId"), out var customerId)
            ? customerId
            : null;

    private bool IsStaff() => User.IsInRole("Broker")
        || User.IsInRole("ComplianceOfficer")
        || User.IsInRole("Administrator");

    private async Task<ExchangeAccounts?> GetExchangeAccountsAsync(long sourceCashAccountId, long targetCashAccountId)
    {
        if (sourceCashAccountId == targetCashAccountId) return null;
        var cashAccounts = await (
            from cash in db.CashAccounts.AsNoTracking()
            join account in db.Accounts.AsNoTracking() on cash.AccountId equals account.AccountId
            where cash.CashAccountId == sourceCashAccountId || cash.CashAccountId == targetCashAccountId
            select new { cash.CashAccountId, cash.Currency, account.CustomerId }
        ).ToListAsync();
        var source = cashAccounts.SingleOrDefault(item => item.CashAccountId == sourceCashAccountId);
        var target = cashAccounts.SingleOrDefault(item => item.CashAccountId == targetCashAccountId);
        if (source is null || target is null || source.CustomerId != target.CustomerId || source.Currency == target.Currency
            || (!IsStaff() && source.CustomerId != GetCustomerId())) return null;
        return new ExchangeAccounts(source.CustomerId, source.Currency, target.Currency);
    }

    private async Task<CurrencyExchangeQuote?> GetExchangeQuoteAsync(string sourceCurrency, string targetCurrency)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = """
            SELECT source.Currency, target.Currency, sourceRate.MidRate, targetRate.MidRate, sourceRate.RateDate, targetRate.RateDate
            FROM (SELECT @sourceCurrency AS Currency) source
            CROSS JOIN (SELECT @targetCurrency AS Currency) target
            OUTER APPLY (SELECT CASE WHEN source.Currency = 'EUR' THEN CAST(1 AS DECIMAL(19,10)) ELSE (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = source.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) END AS MidRate,
                                 CASE WHEN source.Currency = 'EUR' THEN CAST(SYSUTCDATETIME() AS DATE) ELSE (SELECT TOP 1 RateDate FROM core.ExchangeRate WHERE SourceCurrency = source.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) END AS RateDate) sourceRate
            OUTER APPLY (SELECT CASE WHEN target.Currency = 'EUR' THEN CAST(1 AS DECIMAL(19,10)) ELSE (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = target.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) END AS MidRate,
                                 CASE WHEN target.Currency = 'EUR' THEN CAST(SYSUTCDATETIME() AS DATE) ELSE (SELECT TOP 1 RateDate FROM core.ExchangeRate WHERE SourceCurrency = target.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) END AS RateDate) targetRate;
            """;
        command.Parameters.Add(new SqlParameter("@sourceCurrency", sourceCurrency));
        command.Parameters.Add(new SqlParameter("@targetCurrency", targetCurrency));
        await db.Database.OpenConnectionAsync();
        await using var reader = await command.ExecuteReaderAsync();
        if (!await reader.ReadAsync() || reader.IsDBNull(2) || reader.IsDBNull(3)) return null;
        return new CurrencyExchangeQuote(reader.GetString(0), reader.GetString(1), reader.GetDecimal(2) / reader.GetDecimal(3), reader.GetDateTime(4), reader.GetDateTime(5), "ECB_REFERENCE");
    }
}

public record CurrencyExchangeQuote(string SourceCurrency, string TargetCurrency, decimal ExchangeRate, DateTime SourceRateDate, DateTime TargetRateDate, string RateSource);
public record CurrencyExchangeResult(long CurrencyConversionId, string SourceCurrency, string TargetCurrency, decimal SourceAmount, decimal TargetAmount, decimal ExchangeRate, DateTime SourceRateDate, DateTime TargetRateDate, string RateSource);
public record ExchangeAccounts(long CustomerId, string SourceCurrency, string TargetCurrency);
