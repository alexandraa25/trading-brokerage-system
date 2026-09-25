using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Broker,Administrator")]
[ApiController]
[Route("api/broker/alerts")]
public class BrokerAlertsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet("intelligent")]
    public async Task<ActionResult<IEnumerable<BrokerIntelligentAlert>>> Get()
    {
        var activeOrders = await (from order in db.Orders.AsNoTracking()
                                  join instrument in db.Instruments.AsNoTracking() on order.InstrumentId equals instrument.InstrumentId
                                  where order.Status == "Pending" || order.Status == "WaitingTrigger"
                                     || order.Status == "Triggered" || order.Status == "PartiallyExecuted"
                                  select new { order, instrument }).OrderBy(x => x.order.CreatedAt).Take(100).ToListAsync();
        var orderIds = activeOrders.Select(x => x.order.OrderId).ToList();
        var executed = await db.Executions.AsNoTracking().Where(x => orderIds.Contains(x.OrderId)).GroupBy(x => x.OrderId).Select(x => new { OrderId = x.Key, Quantity = x.Sum(i => i.ExecutedQuantity) }).ToDictionaryAsync(x => x.OrderId, x => x.Quantity);
        var alerts = new List<BrokerIntelligentAlert>();

        foreach (var item in activeOrders)
        {
            var elapsed = (int)Math.Floor((DateTime.UtcNow - item.order.CreatedAt).TotalMinutes);
            var executedQuantity = executed.GetValueOrDefault(item.order.OrderId);
            var remaining = Math.Max(0, item.order.Quantity - executedQuantity);
            var quote = await db.Database.SqlQuery<LatestMarketQuote>($"SELECT TOP 1 MarketPrice, QuoteDate FROM trading.MarketQuote WHERE InstrumentId = {item.instrument.InstrumentId} ORDER BY QuoteDate DESC").SingleOrDefaultAsync();

            if (item.order.Status == "PartiallyExecuted")
                alerts.Add(new(item.order.OrderId, item.instrument.Symbol, "High", "Executat parțial", $"Au rămas {remaining:0.####} unități neexecutate.", "Verifică disponibilitatea și execută restul sau respinge ordinul."));
            else if (elapsed >= 60)
                alerts.Add(new(item.order.OrderId, item.instrument.Symbol, "High", "Ordin întârziat", $"Ordinul este în așteptare de {elapsed} minute.", "Verifică imediat prețul și condițiile de execuție."));
            else if (quote is null)
                alerts.Add(new(item.order.OrderId, item.instrument.Symbol, "High", "Cotație indisponibilă", "Nu există o cotație de piață disponibilă pentru validarea execuției.", "Așteaptă o cotație nouă sau respinge ordinul cu motiv."));
            else if (item.order.OrderType == "LIMIT" && item.order.LimitPrice.HasValue && ((item.order.Side == "Buy" && quote.MarketPrice > item.order.LimitPrice) || (item.order.Side == "Sell" && quote.MarketPrice < item.order.LimitPrice)))
                alerts.Add(new(item.order.OrderId, item.instrument.Symbol, "Medium", "Preț în afara limitei", $"Cotația {quote.MarketPrice:0.####} este în afara limitei clientului de {item.order.LimitPrice:0.####}.", "Nu executa la acest preț; urmărește următoarea cotație."));
            else if (elapsed >= 15)
                alerts.Add(new(item.order.OrderId, item.instrument.Symbol, "Medium", "Ordin în așteptare", $"Ordinul nu a fost executat de {elapsed} minute.", "Verifică ordinul și cotația curentă."));
        }
        return Ok(alerts.OrderByDescending(x => x.Severity == "High").ThenBy(x => x.OrderId));
    }
}

public record BrokerIntelligentAlert(long OrderId, string Symbol, string Severity, string Title, string Reason, string SuggestedAction);
