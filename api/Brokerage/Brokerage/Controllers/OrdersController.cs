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
public class OrdersController(BrokerageDbContext db, BrokerNotificationService brokerNotifications) : ControllerBase
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
            where (IsStaff() || (customerId.HasValue && account.CustomerId == customerId.Value))
                && (!IsStaff() || order.Status == "Pending" || order.Status == "PartiallyExecuted")
            orderby order.CreatedAt descending
            select new OrderSummary(
                order.OrderId,
                order.AccountId,
                instrument.Symbol,
                order.Side,
                order.OrderType,
                order.Quantity,
                order.LimitPrice,
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
        if ((request.OrderType == "LIMIT" && (!request.LimitPrice.HasValue || request.LimitPrice <= 0))
            || (request.OrderType == "MARKET" && request.LimitPrice.HasValue))
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

            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return Problem("Procedura de creare a ordinului nu a returnat un rezultat.");

            var result = new CreatedOrder(reader.GetInt64(0), reader.GetString(1));
            await reader.DisposeAsync();
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
