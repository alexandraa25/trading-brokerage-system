using Brokerage.Api.DTOs.Auth;

namespace Brokerage.Api.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
}
