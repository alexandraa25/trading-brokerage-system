using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
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
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = """
            SELECT Currency, MidRate, RateDate, RateSource FROM
            (
                SELECT CAST('EUR' AS CHAR(3)) AS Currency, CAST(1 AS DECIMAL(19,10)) AS MidRate,
                       CAST(SYSUTCDATETIME() AS DATE) AS RateDate, CAST('IDENTITY' AS VARCHAR(50)) AS RateSource
                UNION ALL
                SELECT SourceCurrency, MidRate, RateDate, SourceSystem
                FROM
                (
                    SELECT SourceCurrency, MidRate, RateDate, SourceSystem,
                           ROW_NUMBER() OVER (PARTITION BY SourceCurrency ORDER BY RateDate DESC) AS SequenceNumber
                    FROM core.ExchangeRate WHERE TargetCurrency = 'EUR'
                ) rates WHERE SequenceNumber = 1
            ) valuesForDisplay
            ORDER BY CASE WHEN Currency = 'EUR' THEN 0 ELSE 1 END, Currency;
            """;
        await db.Database.OpenConnectionAsync();
        await using var reader = await command.ExecuteReaderAsync();
        var rates = new List<DisplayExchangeRate>();
        while (await reader.ReadAsync())
            rates.Add(new DisplayExchangeRate(reader.GetString(0), reader.GetDecimal(1), reader.GetDateTime(2), reader.GetString(3)));
        return Ok(rates);
    }
}

public record DisplayExchangeRate(string Currency, decimal MidRate, DateTime RateDate, string RateSource);
