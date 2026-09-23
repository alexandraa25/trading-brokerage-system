using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Cash;

public class DepositRequest
{
    [Range(typeof(decimal), "0.0001", "999999999999999")]
    public decimal Amount { get; init; }

    [StringLength(500)]
    public string? Description { get; init; }
}
