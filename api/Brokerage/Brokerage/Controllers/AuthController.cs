using Brokerage.Api.DTOs.Auth;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Brokerage.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(IAuthService authService, Brokerage.Api.Data.BrokerageDbContext db, Microsoft.AspNetCore.Identity.IPasswordHasher<Brokerage.Api.Models.ApiUser> passwordHasher) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var response = await authService.LoginAsync(request);
        return response is null
            ? Unauthorized(new ProblemDetails { Detail = "Emailul sau parola sunt incorecte." })
            : Ok(response);
    }

    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        var customerId = User.FindFirstValue("customerId");

        return Ok(new
        {
            userId = User.FindFirstValue(ClaimTypes.NameIdentifier),
            email = User.FindFirstValue(ClaimTypes.Email),
            role = User.FindFirstValue(ClaimTypes.Role),
            customerId = long.TryParse(customerId, out var value) ? (long?)value : null
        });
    }

    [Authorize]
    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userId, out var id)) return Forbid();
        var user = await db.ApiUsers.FindAsync(id); if (user is null) return NotFound();
        if (passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.CurrentPassword) == Microsoft.AspNetCore.Identity.PasswordVerificationResult.Failed) return BadRequest(new ProblemDetails { Detail = "Parola curentă nu este corectă." });
        if (request.CurrentPassword == request.NewPassword) return BadRequest(new ProblemDetails { Detail = "Noua parolă trebuie să fie diferită de parola curentă." });
        if (!PasswordPolicy.IsValid(request.NewPassword)) return BadRequest(new ProblemDetails { Detail = PasswordPolicy.Message });
        user.PasswordHash = passwordHasher.HashPassword(user, request.NewPassword); user.UpdatedAt = DateTime.UtcNow; await db.SaveChangesAsync();
        await db.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO audit.AccessAuditLog(ApiUserId, Action, TargetEmail, Details, ChangedBy) VALUES({user.ApiUserId},{"PasswordChanged"},{user.Email},{"Schimbare parolă din profil"},{user.Email})");
        return Ok(new { message = "Parola a fost schimbată cu succes." });
    }
}
