using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[ApiController]
[Route("api/registration")]
public class RegistrationController(BrokerageDbContext db, IPasswordHasher<ApiUser> passwordHasher) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost]
    public Task<IActionResult> Register(RegisterCustomerRequest request) => CreateAsync(request);

    [Authorize(Roles = "Administrator")]
    [HttpPost("admin")]
    public Task<IActionResult> CreateForAdmin(RegisterCustomerRequest request) => CreateAsync(request);

    private async Task<IActionResult> CreateAsync(RegisterCustomerRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName) || request.Password.Length < 8)
            return BadRequest(new ProblemDetails { Detail = "Prenumele, numele și o parolă de cel puțin 8 caractere sunt obligatorii." });
        if (await db.Customers.AnyAsync(item => item.Email == email) || await db.ApiUsers.AnyAsync(item => item.Email == email))
            return Conflict(new ProblemDetails { Detail = "Există deja un client cu această adresă de email." });

        var customerTypeId = await db.CustomerTypes.AsNoTracking()
            .Where(item => item.IsActive)
            .OrderBy(item => item.CustomerTypeId)
            .Select(item => item.CustomerTypeId)
            .FirstOrDefaultAsync();
        if (customerTypeId == 0) return Problem("Nu este configurat un tip de client activ.");

        await using var transaction = await db.Database.BeginTransactionAsync();
        var customer = new Customer { CustomerTypeId = customerTypeId, FirstName = request.FirstName.Trim(), LastName = request.LastName.Trim(), Email = email, Status = "Active" };
        db.Customers.Add(customer);
        await db.SaveChangesAsync();

        var account = new TradingAccount { CustomerId = customer.CustomerId, AccountNumber = $"TRD-{customer.CustomerId:D8}", Currency = "EUR", Status = "Active" };
        db.Accounts.Add(account);
        db.KycRecords.Add(new KycRecord { CustomerId = customer.CustomerId, Status = "Pending", DocumentType = request.DocumentType?.Trim() });
        var user = new ApiUser { ApiUserId = Guid.NewGuid(), CustomerId = customer.CustomerId, Email = email, Role = "Customer", IsActive = true };
        user.PasswordHash = passwordHasher.HashPassword(user, request.Password);
        db.ApiUsers.Add(user);
        await db.SaveChangesAsync();

        db.CashAccounts.Add(new CashAccount { AccountId = account.AccountId, Currency = "EUR", AvailableBalance = 0, BlockedBalance = 0 });
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return Created("/api/auth/login", new { customerId = customer.CustomerId, accountId = account.AccountId, message = "Clientul a fost creat. Dosarul KYC așteaptă aprobare." });
    }
}

public record RegisterCustomerRequest(string FirstName, string LastName, string Email, string Password, string? DocumentType);
