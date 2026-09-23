using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Cash;

public class CurrencyExchangeRequest
{
    public long SourceCashAccountId { get; init; }
    public long TargetCashAccountId { get; init; }

    [Range(typeof(decimal), "0.0001", "999999999999999")]
    public decimal SourceAmount { get; init; }
}
