using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Executions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;
using Brokerage.Api.Services;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Broker,Administrator")]
[ApiController]
[Route("api/orders/{orderId:long}/executions")]
public class ExecutionsController(BrokerageDbContext db, CustomerNotificationService notifications, BrokerNotificationService brokerNotifications) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ExecutionResult>> ExecuteOrder(
        long orderId,
        ExecuteOrderRequest request)
    {
        var orderDetails = await (
            from order in db.Orders.AsNoTracking()
            join account in db.Accounts.AsNoTracking() on order.AccountId equals account.AccountId
            join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
            where order.OrderId == orderId
            select new { account.CustomerId, instrument.Symbol, order.Side }
        ).SingleOrDefaultAsync();
        if (orderDetails is null)
            return NotFound();

        try
        {
            await using var connection = db.Database.GetDbConnection();
            await connection.OpenAsync();
            await using var command = connection.CreateCommand();
            command.CommandText = "trading.usp_ExecuteOrder";
            command.CommandType = CommandType.StoredProcedure;
            command.Parameters.Add(new SqlParameter("@OrderId", orderId));
            command.Parameters.Add(new SqlParameter("@ExecutedQuantity", request.ExecutedQuantity));
            command.Parameters.Add(new SqlParameter("@ExecutionPrice", request.ExecutionPrice));

            await using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return Problem("Procedura de execuție nu a returnat un rezultat.");

            var result = new ExecutionResult(
                reader.GetInt64(0),
                reader.GetInt64(1),
                reader.GetDecimal(2),
                reader.GetDecimal(3),
                reader.GetDecimal(4),
                reader.GetDecimal(5),
                reader.GetString(6),
                reader.GetDecimal(7),
                reader.GetDateTime(8),
                reader.GetString(9),
                reader.GetDecimal(10),
                reader.GetDecimal(11),
                reader.GetString(12),
                reader.GetString(13));

            await reader.DisposeAsync();
            await notifications.CreateAsync(orderDetails.CustomerId, "Execution", "Ordin executat",
                $"Ordinul {orderDetails.Side} pentru {orderDetails.Symbol} a fost executat: {request.ExecutedQuantity:0.####} la prețul {request.ExecutionPrice:0.####}.");
            await brokerNotifications.CreateAsync("Execution", "Execuție înregistrată",
                $"Ordinul #{orderId} pentru {orderDetails.Symbol} a fost executat: {request.ExecutedQuantity:0.####} la {request.ExecutionPrice:0.####}.");

            return Ok(result);
        }
        catch (SqlException exception) when (exception.Number is >= 50000 and < 60000)
        {
            await brokerNotifications.CreateAsync("ExecutionBlocked", "Execuție blocată",
                $"Ordinul #{orderId} nu a putut fi executat: {exception.Message}");
            return BadRequest(new ProblemDetails { Detail = exception.Message });
        }
    }
}
