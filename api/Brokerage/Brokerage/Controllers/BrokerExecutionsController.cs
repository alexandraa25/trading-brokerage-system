using Brokerage.Api.Data;
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
    public async Task<IActionResult> GetRecentExecutions()
    {
        var executions = await (
            from execution in db.Executions.AsNoTracking()
            join order in db.Orders.AsNoTracking() on execution.OrderId equals order.OrderId
            join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
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
            }).Take(100).ToListAsync();

        return Ok(executions);
    }
}
