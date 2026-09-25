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
        var instruments = await db.Database.SqlQuery<InstrumentSummary>($"""
            SELECT instrument.InstrumentId, instrument.Symbol, instrument.InstrumentName, instrument.InstrumentType,
                   instrument.Currency, market.MarketName, issuer.IssuerName,
                   quote.MarketPrice, quote.QuoteDate, quote.SourceSystem AS QuoteSource
            FROM trading.Instrument instrument
            INNER JOIN trading.Market market ON market.MarketId = instrument.MarketId
            INNER JOIN trading.Issuer issuer ON issuer.IssuerId = instrument.IssuerId
            OUTER APPLY
            (
                SELECT TOP 1 MarketPrice, QuoteDate, SourceSystem
                FROM trading.MarketQuote
                WHERE InstrumentId = instrument.InstrumentId
                ORDER BY QuoteDate DESC
            ) quote
            WHERE instrument.IsActive = 1
            ORDER BY instrument.Symbol
            """).ToListAsync();

        return Ok(instruments);
    }

    [HttpGet("{instrumentId:long}/quotes")]
    public async Task<ActionResult<IEnumerable<InstrumentQuotePoint>>> GetQuoteHistory(long instrumentId, [FromQuery] int days = 30)
    {
        days = Math.Clamp(days, 7, 365);
        if (!await db.Instruments.AnyAsync(x => x.InstrumentId == instrumentId && x.IsActive)) return NotFound();
        var quotes = await db.Database.SqlQuery<InstrumentQuotePoint>($"""
            SELECT TOP ({days}) QuoteDate, MarketPrice
            FROM trading.MarketQuote
            WHERE InstrumentId = {instrumentId}
            ORDER BY QuoteDate DESC
            """).ToListAsync();
        quotes.Reverse();
        return Ok(quotes);
    }
}

public record InstrumentQuotePoint(DateTime QuoteDate, decimal MarketPrice);
