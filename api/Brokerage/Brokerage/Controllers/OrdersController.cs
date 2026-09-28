using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Orders;
using Brokerage.Api.DTOs.History;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;
using System.Security.Claims;
using Brokerage.Api.Services;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/orders")]
public class OrdersController(BrokerageDbContext db, BrokerNotificationService brokerNotifications, OrderAuditService orderAudit) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrderSummary>>> GetOrders()
    {
        var customerId = GetCustomerId();

        var orders = await (
            from order in db.Orders.AsNoTracking()
            join account in db.Accounts.AsNoTracking()
                on order.AccountId equals account.AccountId
            join instrument in db.Instruments.AsNoTracking()
                on order.InstrumentId equals instrument.InstrumentId
            let executedQuantity = db.Executions.Where(item => item.OrderId == order.OrderId).Sum(item => (decimal?)item.ExecutedQuantity) ?? 0
            where (IsStaff() || (customerId.HasValue && account.CustomerId == customerId.Value))
                && (!IsStaff() || order.Status == "Pending" || order.Status == "WaitingTrigger"
                    || order.Status == "Triggered" || order.Status == "PartiallyExecuted")
            orderby order.CreatedAt descending
            select new OrderSummary(
                order.OrderId,
                order.AccountId,
                instrument.Symbol,
                order.Side,
                order.OrderType,
                order.Quantity,
                order.LimitPrice,
                order.StopPrice,
                order.OriginalQuantity ?? order.Quantity + order.CancelledQuantity,
                executedQuantity,
                order.CancelledQuantity,
                order.Quantity - executedQuantity,
                order.Status,
                order.CreatedAt)
        ).Take(IsStaff() ? 100 : int.MaxValue).ToListAsync();

        return Ok(orders);
    }

    [HttpGet("{orderId:long}")]
    public async Task<ActionResult<OrderSummary>> GetOrder(long orderId)
    {
        var customerId = GetCustomerId();

        var order = await (
            from tradeOrder in db.Orders.AsNoTracking()
            join account in db.Accounts.AsNoTracking()
                on tradeOrder.AccountId equals account.AccountId
            join instrument in db.Instruments.AsNoTracking()
                on tradeOrder.InstrumentId equals instrument.InstrumentId
            let executedQuantity = db.Executions.Where(item => item.OrderId == tradeOrder.OrderId).Sum(item => (decimal?)item.ExecutedQuantity) ?? 0
            where tradeOrder.OrderId == orderId
                && (IsStaff() || (customerId.HasValue && account.CustomerId == customerId.Value))
            select new OrderSummary(
                tradeOrder.OrderId,
                tradeOrder.AccountId,
                instrument.Symbol,
                tradeOrder.Side,
                tradeOrder.OrderType,
                tradeOrder.Quantity,
                tradeOrder.LimitPrice,
                tradeOrder.StopPrice,
                tradeOrder.OriginalQuantity ?? tradeOrder.Quantity + tradeOrder.CancelledQuantity,
                executedQuantity,
                tradeOrder.CancelledQuantity,
                tradeOrder.Quantity - executedQuantity,
                tradeOrder.Status,
                tradeOrder.CreatedAt)
        ).SingleOrDefaultAsync();

        return order is null ? NotFound() : Ok(order);
    }

    [HttpGet("{orderId:long}/executions")]
    public async Task<ActionResult<IEnumerable<ExecutionSummary>>> GetExecutions(long orderId)
    {
        if (!await CanAccessOrderAsync(orderId))
            return NotFound();

        var executions = await db.Executions
            .AsNoTracking()
            .Where(execution => execution.OrderId == orderId)
            .OrderByDescending(execution => execution.ExecutedAt)
            .Select(execution => new ExecutionSummary(
                execution.ExecutionId,
                execution.ExecutedQuantity,
                execution.ExecutionPrice,
                execution.ExecutedAt,
                execution.TradeCurrency,
                execution.ExchangeRateToReporting,
                execution.ExchangeRateDate,
                execution.ExchangeRateSource,
                execution.TradeValueReporting,
                execution.CommissionReporting))
            .ToListAsync();

        return Ok(executions);
    }

    [HttpPost]
    public async Task<ActionResult<CreatedOrder>> CreateOrder(CreateOrderRequest request)
    {
        if ((request.OrderType == "LIMIT" && (!request.LimitPrice.HasValue || request.LimitPrice <= 0)) || ((request.OrderType == "STOP" || request.OrderType == "STOP_LIMIT") && (!request.StopPrice.HasValue || request.StopPrice <= 0)) || (request.OrderType == "STOP_LIMIT" && (!request.LimitPrice.HasValue || request.LimitPrice <= 0)))
        {
            ModelState.AddModelError(nameof(request.LimitPrice),
                "Prețul limită este obligatoriu doar pentru ordine LIMIT.");
            return ValidationProblem(ModelState);
        }

        if (!await CanAccessAccountAsync(request.AccountId))
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_CreateOrder";
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.Add(new SqlParameter("@AccountId", request.AccountId));
            command.Parameters.Add(new SqlParameter("@InstrumentId", request.InstrumentId));
            command.Parameters.Add(new SqlParameter("@Side", request.Side));
            command.Parameters.Add(new SqlParameter("@OrderType", request.OrderType));
            command.Parameters.Add(new SqlParameter("@Quantity", request.Quantity));
            command.Parameters.Add(new SqlParameter("@LimitPrice", request.LimitPrice ?? (object)DBNull.Value));
            command.Parameters.Add(new SqlParameter("@StopPrice", request.StopPrice ?? (object)DBNull.Value));

            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return Problem("Procedura de creare a ordinului nu a returnat un rezultat.");

            var result = new CreatedOrder(reader.GetInt64(0), reader.GetString(1));
            await reader.DisposeAsync();
            var savedOrder = await db.Orders.SingleAsync(item => item.OrderId == result.OrderId);
            savedOrder.TimeInForce = request.TimeInForce;
            savedOrder.ExpiresAt = request.TimeInForce == "DATE" ? request.ExpiresAt?.ToUniversalTime() : null;
            await db.SaveChangesAsync();
            if (!IsStaff())
            {
                await brokerNotifications.CreateAsync("NewOrder", "Ordin nou în așteptare",
                    $"Ordinul #{result.OrderId} pentru {request.Quantity:0.####} unități a fost trimis spre execuție.");
            }
            return CreatedAtAction(nameof(GetOrder), new { result.OrderId }, result);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    [HttpPost("estimate")]
    public async Task<ActionResult<OrderEstimate>> EstimateOrder(CreateOrderRequest request)
    {
        if (!await CanAccessAccountAsync(request.AccountId)) return NotFound();

        var instrument = await db.Instruments.AsNoTracking()
            .Where(item => item.InstrumentId == request.InstrumentId && item.IsActive)
            .Select(item => new { item.InstrumentId, item.Currency })
            .SingleOrDefaultAsync();
        if (instrument is null) return NotFound();

        var quote = db.Database.ProviderName?.Contains("Sqlite", StringComparison.OrdinalIgnoreCase) == true
            ? await db.Database.SqlQuery<OrderEstimateQuote>($"""SELECT MarketPrice, QuoteDate FROM trading.MarketQuote WHERE InstrumentId = {instrument.InstrumentId} ORDER BY QuoteDate DESC LIMIT 1""").SingleOrDefaultAsync()
            : await db.Database.SqlQuery<OrderEstimateQuote>($"""SELECT TOP 1 MarketPrice, QuoteDate FROM trading.MarketQuote WHERE InstrumentId = {instrument.InstrumentId} ORDER BY QuoteDate DESC""").SingleOrDefaultAsync();
        if (quote is null)
            return BadRequest(new ProblemDetails { Detail = "Nu există o cotație disponibilă pentru acest instrument." });

        var price = request.OrderType is "LIMIT" or "STOP_LIMIT" ? request.LimitPrice ?? 0 : quote.MarketPrice;
        if (request.Quantity <= 0 || price <= 0)
            return ValidationProblem("Cantitatea și prețul estimat trebuie să fie pozitive.");

        var orderValue = decimal.Round(request.Quantity * price, 4);
        var commission = decimal.Round(orderValue * 0.0025m, 4);
        var requiredAmount = request.Side == "BUY" ? orderValue + commission : request.Quantity;
        decimal availableAmount;
        string? reason = null;
        if (request.Side == "BUY")
        {
            availableAmount = await db.CashAccounts.AsNoTracking()
                .Where(item => item.AccountId == request.AccountId && item.Currency == instrument.Currency)
                .Select(item => (decimal?)item.AvailableBalance).SingleOrDefaultAsync() ?? 0;
            if (availableAmount < requiredAmount) reason = "Soldul disponibil nu acoperă valoarea ordinului și comisionul estimat.";
        }
        else
        {
            availableAmount = await db.Positions.AsNoTracking()
                .Where(item => item.AccountId == request.AccountId && item.InstrumentId == request.InstrumentId)
                .Select(item => (decimal?)item.Quantity).SingleOrDefaultAsync() ?? 0;
            if (availableAmount < requiredAmount) reason = "Cantitatea disponibilă în poziție nu acoperă ordinul de vânzare.";
        }

        var estimate = new OrderEstimate(instrument.Currency, price, quote.QuoteDate, orderValue, commission,
            requiredAmount, availableAmount, decimal.Max(requiredAmount - availableAmount, 0),
            availableAmount >= requiredAmount, reason);
        await orderAudit.LogAsync(null, "OrderEstimate",
            $"Cont #{request.AccountId}; instrument #{request.InstrumentId}; {request.Side} {request.Quantity:0.####}; preț {price:0.####}; comision {commission:0.####}; rezultat {(estimate.CanSubmit ? "acceptat" : "fonduri insuficiente")}",
            User.Identity?.Name ?? "Utilizator");
        return Ok(estimate);
    }

    [HttpPost("{orderId:long}/cancel")]
    public async Task<ActionResult<CreatedOrder>> CancelOrder(long orderId)
    {
        if (!await CanAccessOrderAsync(orderId))
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_CancelOrder";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@OrderId", orderId));

            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return Problem("Procedura de anulare nu a returnat un rezultat.");

            return Ok(new CreatedOrder(reader.GetInt64(0), reader.GetString(1)));
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    [HttpPost("{orderId:long}/cancel-partial")]
    public async Task<ActionResult<PartialOrderCancellationResult>> CancelOrderPartially(
        long orderId,
        PartialOrderCancellationRequest request)
    {
        if (!await CanAccessOrderAsync(orderId))
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_CancelOrderPartially";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@OrderId", orderId));
            command.Parameters.Add(new SqlParameter("@CancelledQuantity", request.CancelledQuantity));

            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return Problem("Procedura de anulare parțială nu a returnat un rezultat.");

            var result = new PartialOrderCancellationResult(reader.GetInt64(0), reader.GetDecimal(1), reader.GetDecimal(2));
            await reader.DisposeAsync();
            await orderAudit.LogAsync(orderId, "PartialCancellation",
                $"Cantitate anulată {result.CancelledQuantity:0.####}; cantitate rămasă {result.RemainingQuantity:0.####}",
                User.Identity?.Name ?? "Utilizator");
            return Ok(result);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }

    private async Task<bool> CanAccessAccountAsync(long accountId)
    {
        if (IsStaff())
            return await db.Accounts.AnyAsync(account => account.AccountId == accountId);

        var customerId = GetCustomerId();
        return customerId.HasValue && await db.Accounts.AnyAsync(account =>
            account.AccountId == accountId && account.CustomerId == customerId.Value);
    }

    private async Task<bool> CanAccessOrderAsync(long orderId)
    {
        if (IsStaff())
            return await db.Orders.AnyAsync(order => order.OrderId == orderId);

        var customerId = GetCustomerId();
        return customerId.HasValue && await (
            from order in db.Orders
            join account in db.Accounts on order.AccountId equals account.AccountId
            where order.OrderId == orderId && account.CustomerId == customerId.Value
            select order.OrderId
        ).AnyAsync();
    }

    private long? GetCustomerId() =>
        long.TryParse(User.FindFirstValue("customerId"), out var customerId)
            ? customerId
            : null;

    private bool IsStaff() => User.IsInRole("Broker")
        || User.IsInRole("ComplianceOfficer")
        || User.IsInRole("Administrator");
}

public record OrderEstimateQuote(decimal MarketPrice, DateTime QuoteDate);
