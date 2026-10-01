using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Instruments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/instruments")]
public class InstrumentsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<InstrumentSummary>>> GetInstruments()
    {
        var instruments = await (
            from instrument in db.Instruments.AsNoTracking()
            join market in db.Markets.AsNoTracking() on instrument.MarketId equals market.MarketId
            join issuer in db.Issuers.AsNoTracking() on instrument.IssuerId equals issuer.IssuerId
            let quote = db.MarketQuotes.AsNoTracking()
                .Where(item => item.InstrumentId == instrument.InstrumentId)
                .OrderByDescending(item => item.QuoteDate)
                .Select(item => new { item.MarketPrice, item.QuoteDate, item.SourceSystem })
                .FirstOrDefault()
            where instrument.IsActive
            orderby instrument.Symbol
            select new InstrumentSummary(
                instrument.InstrumentId, instrument.Symbol, instrument.InstrumentName, instrument.InstrumentType,
                instrument.Currency, market.MarketName, issuer.IssuerName,
                quote == null ? null : quote.MarketPrice,
                quote == null ? null : quote.QuoteDate,
                quote == null ? null : quote.SourceSystem)
        ).ToListAsync();

        return Ok(instruments);
    }

    [HttpGet("{instrumentId:long}/quotes")]
    public async Task<ActionResult<IEnumerable<InstrumentQuotePoint>>> GetQuoteHistory(long instrumentId, [FromQuery] int days = 30)
    {
        days = Math.Clamp(days, 7, 365);
        if (!await db.Instruments.AnyAsync(x => x.InstrumentId == instrumentId && x.IsActive)) return NotFound();
        var quotes = await db.MarketQuotes.AsNoTracking()
            .Where(quote => quote.InstrumentId == instrumentId)
            .OrderByDescending(quote => quote.QuoteDate)
            .Take(days)
            .Select(quote => new InstrumentQuotePoint(quote.QuoteDate, quote.MarketPrice))
            .ToListAsync();
        quotes.Reverse();
        return Ok(quotes);
    }
}

public record InstrumentQuotePoint(DateTime QuoteDate, decimal MarketPrice);
