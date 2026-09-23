using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Cash;

public class OpenCashAccountRequest
{
    [Required]
    [RegularExpression("^[A-Z]{3}$")]
    public string Currency { get; init; } = string.Empty;
}
