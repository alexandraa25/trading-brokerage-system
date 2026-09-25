using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Orders;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Broker,Administrator")]
[ApiController]
[Route("api/broker/orders")]
public class BrokerOrdersController(BrokerageDbContext db, CustomerNotificationService notifications) : ControllerBase
{
    [HttpGet("history")]
    public async Task<ActionResult<IEnumerable<OrderSummary>>> GetOrderHistory()
    {
        var orders = await (
            from order in db.Orders.AsNoTracking()
            join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
            let executedQuantity = db.Executions.Where(item => item.OrderId == order.OrderId).Sum(item => (decimal?)item.ExecutedQuantity) ?? 0
            orderby order.CreatedAt descending
            select new OrderSummary(
                order.OrderId, order.AccountId, instrument.Symbol, order.Side, order.OrderType,
                order.Quantity, order.LimitPrice, order.StopPrice,
                order.OriginalQuantity ?? order.Quantity + order.CancelledQuantity,
                executedQuantity, order.CancelledQuantity, order.Quantity - executedQuantity,
                order.Status, order.CreatedAt)
        ).Take(500).ToListAsync();

        return Ok(orders);
    }

    [HttpGet("{orderId:long}/details")]
    public async Task<IActionResult> GetOrderDetails(long orderId)
    {
        var details = await (
            from order in db.Orders.AsNoTracking()
            join account in db.Accounts.AsNoTracking() on order.AccountId equals account.AccountId
            join customer in db.Customers.AsNoTracking() on account.CustomerId equals customer.CustomerId
            join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
            where order.OrderId == orderId
            select new { order, account, customer, instrument }
        ).SingleOrDefaultAsync();
        if (details is null) return NotFound();

        var cash = await db.CashAccounts.AsNoTracking()
            .Where(item => item.AccountId == details.account.AccountId && item.Currency == details.instrument.Currency)
            .Select(item => new { item.AvailableBalance, item.BlockedBalance })
            .SingleOrDefaultAsync();
        var position = await db.Positions.AsNoTracking()
            .Where(item => item.AccountId == details.account.AccountId && item.InstrumentId == details.instrument.InstrumentId)
            .Select(item => new { item.Quantity, item.AveragePrice })
            .SingleOrDefaultAsync();
        var executedQuantity = await db.Executions.AsNoTracking()
            .Where(item => item.OrderId == orderId)
            .Select(item => (decimal?)item.ExecutedQuantity).SumAsync() ?? 0;
        var latestQuote = await db.Database.SqlQuery<LatestMarketQuote>($"""
            SELECT TOP 1 MarketPrice, QuoteDate
            FROM trading.MarketQuote
            WHERE InstrumentId = {details.instrument.InstrumentId}
            ORDER BY QuoteDate DESC
            """).SingleOrDefaultAsync();

        return Ok(new BrokerOrderDetails(
            details.order.OrderId, details.instrument.Symbol, details.instrument.InstrumentName,
            details.order.Side, details.order.OrderType, details.order.Quantity, details.order.LimitPrice,
            details.order.Status, details.order.CreatedAt, details.customer.FirstName, details.customer.LastName,
            details.customer.Email, details.account.AccountNumber, details.instrument.Currency,
            cash?.AvailableBalance ?? 0, cash?.BlockedBalance ?? 0, position?.Quantity ?? 0,
            position?.AveragePrice ?? 0, executedQuantity, latestQuote?.MarketPrice, latestQuote?.QuoteDate));
    }

    [HttpPost("{orderId:long}/reject")]
    public async Task<IActionResult> RejectOrder(long orderId, RejectOrderRequest request)
    {
        var order = await (
            from tradeOrder in db.Orders.AsNoTracking()
            join account in db.Accounts.AsNoTracking() on tradeOrder.AccountId equals account.AccountId
            join instrument in db.Instruments.AsNoTracking() on tradeOrder.InstrumentId equals instrument.InstrumentId
            where tradeOrder.OrderId == orderId
            select new { account.CustomerId, instrument.Symbol }
        ).SingleOrDefaultAsync();
        if (order is null) return NotFound();
        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_RejectOrder";
            command.CommandType = System.Data.CommandType.StoredProcedure;
            command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@OrderId", orderId));
            command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@Reason", request.Reason.Trim()));
            command.Parameters.Add(new Microsoft.Data.SqlClient.SqlParameter("@DecidedBy", User.Identity?.Name ?? "Broker"));
            await command.ExecuteNonQueryAsync();
            await notifications.CreateAsync(order.CustomerId, "OrderRejected", "Ordin respins de broker",
                $"Ordinul pentru {order.Symbol} a fost respins. Motiv: {request.Reason.Trim()}");
            return Ok(new { orderId, Status = "Rejected" });
        }
        catch (Microsoft.Data.SqlClient.SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }
}

public record BrokerOrderDetails(long OrderId, string Symbol, string InstrumentName, string Side,
    string OrderType, decimal Quantity, decimal? LimitPrice, string Status, DateTime CreatedAt,
    string FirstName, string LastName, string Email, string AccountNumber, string Currency,
    decimal AvailableCash, decimal BlockedCash, decimal PositionQuantity, decimal AveragePrice,
    decimal ExecutedQuantity, decimal? MarketPrice, DateTime? QuoteDate);

public record LatestMarketQuote(decimal MarketPrice, DateTime QuoteDate);
