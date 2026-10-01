using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Broker,Administrator")]
[ApiController]
[Route("api/broker/executions")]
public class BrokerExecutionsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetRecentExecutions(
        [FromQuery] PageRequest pageRequest,
        [FromQuery] string? symbol = null)
    {
        var executions = (
            from execution in db.Executions.AsNoTracking()
            join order in db.Orders.AsNoTracking() on execution.OrderId equals order.OrderId
            join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
            where string.IsNullOrWhiteSpace(symbol) || instrument.Symbol.Contains(symbol)
            orderby execution.ExecutedAt descending
            select new
            {
                execution.ExecutionId,
                execution.OrderId,
                instrument.Symbol,
                order.Side,
                execution.ExecutedQuantity,
                execution.ExecutionPrice,
                execution.TradeCurrency,
                execution.CommissionReporting,
                execution.ExchangeRateToReporting,
                execution.ExchangeRateDate,
                execution.ExchangeRateSource,
                execution.TradeValueReporting,
                execution.ExecutedAt
            });

        return Ok(await executions.ToPagedResultAsync(pageRequest));
    }
}
