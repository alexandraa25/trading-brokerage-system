using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/exchange-rates")]
public class ExchangeRatesController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet("display")]
    public async Task<IActionResult> GetDisplayRates()
    {
        var reportingCurrency = await db.Currencies.AsNoTracking()
            .Where(currency => currency.IsReportingCurrency)
            .Select(currency => currency.CurrencyCode)
            .SingleOrDefaultAsync() ?? "EUR";

        var latestRates = await db.ExchangeRates.AsNoTracking()
            .Where(rate => rate.TargetCurrency == reportingCurrency)
            .GroupBy(rate => rate.SourceCurrency)
            .Select(group => group.OrderByDescending(rate => rate.RateDate).ThenByDescending(rate => rate.ExchangeRateId).First())
            .Select(rate => new DisplayExchangeRate(rate.SourceCurrency, rate.MidRate, rate.RateDate, rate.SourceSystem))
            .OrderBy(rate => rate.Currency)
            .ToListAsync();

        latestRates.Insert(0, new DisplayExchangeRate(reportingCurrency, 1m, DateTime.UtcNow.Date, "IDENTITY"));
        return Ok(latestRates);
    }
}

public record DisplayExchangeRate(string Currency, decimal MidRate, DateTime RateDate, string RateSource);
