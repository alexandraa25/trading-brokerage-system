using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Auth;

public class LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required, MinLength(8)]
    public string Password { get; init; } = string.Empty;
}
