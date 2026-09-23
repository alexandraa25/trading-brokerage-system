using Brokerage.Api.Data;
using Brokerage.Api.DTOs.Auth;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Brokerage.Api.Services;

public class AuthService : IAuthService
{
    private readonly BrokerageDbContext _db;
    private readonly IPasswordHasher<ApiUser> _passwordHasher;
    private readonly IConfiguration _configuration;

    public AuthService(
        BrokerageDbContext db,
        IPasswordHasher<ApiUser> passwordHasher,
        IConfiguration configuration)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _configuration = configuration;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        string normalizedEmail = request.Email.Trim().ToLowerInvariant();

        var user = await _db.ApiUsers
            .SingleOrDefaultAsync(x => x.Email == normalizedEmail);

        if (user is null || !user.IsActive)
            return null;

        var passwordResult =
            _passwordHasher.VerifyHashedPassword(
                user,
                user.PasswordHash,
                request.Password);

        if (passwordResult == PasswordVerificationResult.Failed)
            return null;

        var token = GenerateJwtToken(user);

        return new LoginResponse
        {
            Token = token.Token,
            ExpiresAt = token.ExpiresAt,
            Role = user.Role,
            CustomerId = user.CustomerId
        };
    }

    private (string Token, DateTime ExpiresAt)
        GenerateJwtToken(ApiUser user)
    {
        var jwtKey = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException(
                "JWT key is not configured.");

        var issuer = _configuration["Jwt:Issuer"]
            ?? throw new InvalidOperationException(
                "JWT issuer is not configured.");

        var audience = _configuration["Jwt:Audience"]
            ?? throw new InvalidOperationException(
                "JWT audience is not configured.");

        var expiresAt = DateTime.UtcNow.AddMinutes(60);

        var claims = new List<Claim>
        {
            new(
                JwtRegisteredClaimNames.Sub,
                user.ApiUserId.ToString()),

            new(
                JwtRegisteredClaimNames.Email,
                user.Email),

            new(
                ClaimTypes.Role,
                user.Role)
        };

        if (user.CustomerId.HasValue)
        {
            claims.Add(
                new Claim(
                    "customerId",
                    user.CustomerId.Value.ToString()));
        }

        var signingKey =
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtKey));

        var credentials =
            new SigningCredentials(
                signingKey,
                SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return (
            new JwtSecurityTokenHandler().WriteToken(token),
            expiresAt
        );
    }
}
