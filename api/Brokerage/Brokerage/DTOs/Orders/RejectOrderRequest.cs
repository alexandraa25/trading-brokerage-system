using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Orders;

public class RejectOrderRequest
{
    [Required, StringLength(500, MinimumLength = 3)]
    public string Reason { get; init; } = string.Empty;
}
