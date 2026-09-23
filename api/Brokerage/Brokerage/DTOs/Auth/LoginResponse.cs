namespace Brokerage.Api.DTOs.Auth;

public class LoginResponse
{
    public string Token { get; init; } = string.Empty;
    public DateTime ExpiresAt { get; init; }
    public string Role { get; init; } = string.Empty;
    public long? CustomerId { get; init; }
}
