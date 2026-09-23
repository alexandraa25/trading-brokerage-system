using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Orders;

public class CreateOrderRequest
{
    [Range(1, long.MaxValue)]
    public long AccountId { get; init; }

    [Range(1, long.MaxValue)]
    public long InstrumentId { get; init; }

    [Required, RegularExpression("^(BUY|SELL)$")]
    public string Side { get; init; } = string.Empty;

    [Required, RegularExpression("^(MARKET|LIMIT)$")]
    public string OrderType { get; init; } = string.Empty;

    [Range(typeof(decimal), "0.00000001", "99999999999")]
    public decimal Quantity { get; init; }

    public decimal? LimitPrice { get; init; }
}

public record OrderSummary(
    long OrderId,
    long AccountId,
    string Symbol,
    string Side,
    string OrderType,
    decimal Quantity,
    decimal? LimitPrice,
    string Status,
    DateTime CreatedAt);

public record CreatedOrder(long OrderId, string Status);
