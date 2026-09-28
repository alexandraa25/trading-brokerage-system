using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Administrator")]
[ApiController]
[Route("api/admin")]
public class AdminOperationsController(BrokerageDbContext db, IPasswordHasher<ApiUser> passwordHasher) : ControllerBase
{
    [HttpPost("users")]
    public async Task<IActionResult> CreateUser(CreateStaffUserRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (request.Role is not ("Broker" or "Administrator") || request.Password.Length < 8)
            return BadRequest(new ProblemDetails { Detail = "Rolul trebuie să fie Broker sau Administrator, iar parola trebuie să aibă minimum 8 caractere." });
        if (await db.ApiUsers.AnyAsync(item => item.Email == email)) return Conflict(new ProblemDetails { Detail = "Există deja un utilizator cu acest email." });
        var user = new ApiUser { ApiUserId = Guid.NewGuid(), Email = email, Role = request.Role, IsActive = true };
        user.PasswordHash = passwordHasher.HashPassword(user, request.Password);
        db.ApiUsers.Add(user); await db.SaveChangesAsync();
        await AuditAsync(user, "Created", email, $"Rol: {request.Role}");
        return Ok(new { user.ApiUserId, user.Email, user.Role });
    }
    [HttpGet("overview")]
    public async Task<IActionResult> Overview()
    {
        var today = DateTime.UtcNow.Date;
        var latestRateDate = await db.Database.SqlQuery<DateTime?>($"SELECT MAX(RateDate) AS Value FROM core.ExchangeRate").SingleAsync();
        var latestQuoteDate = await db.Database.SqlQuery<DateTime?>($"SELECT MAX(QuoteDate) AS Value FROM trading.MarketQuote").SingleAsync();
        return Ok(new {
            ActiveCustomers = await db.Customers.CountAsync(item => item.Status == "Active"),
            PendingKyc = await db.KycRecords.CountAsync(item => item.Status == "Pending"),
        ActiveOrders = await db.Orders.CountAsync(item => item.Status == "Pending" || item.Status == "WaitingTrigger" || item.Status == "Triggered" || item.Status == "PartiallyExecuted"),
            DailyExecutions = await db.Executions.CountAsync(item => item.ExecutedAt >= today),
            BlockedCustomers = await db.Customers.CountAsync(item => item.Status == "Blocked"),
            DelayedKyc = await db.KycRecords.CountAsync(item => item.Status == "Pending" && item.CreatedAt < today.AddDays(-7)),
            LatestRateDate = latestRateDate,
            ExchangeRateOutdated = !latestRateDate.HasValue || latestRateDate.Value.Date < today.AddDays(-3),
            LatestQuoteDate = latestQuoteDate,
            MarketQuotesOutdated = !latestQuoteDate.HasValue || latestQuoteDate.Value.Date < today.AddDays(-1)
        });
    }

    [HttpPost("accounts/{accountId:long}/status")]
    public async Task<IActionResult> UpdateAccountStatus(long accountId, AccountStatusRequest request)
    {
        if (request.Status is not ("Active" or "Suspended") || string.IsNullOrWhiteSpace(request.Reason)) return BadRequest(new ProblemDetails { Detail = "Starea contului și motivul sunt obligatorii." });
        var account = await db.Accounts.FindAsync(accountId);
        if (account is null) return NotFound();
        if (request.Status == "Active")
        {
            var kycApproved = await db.KycRecords.AnyAsync(item => item.CustomerId == account.CustomerId && item.Status == "Approved");
            if (!kycApproved) return BadRequest(new ProblemDetails { Detail = "Contul poate fi reactivat numai după aprobarea KYC." });
        }
        var previousStatus = account.Status;
        account.Status = request.Status;
        await db.SaveChangesAsync();
        var changedBy = User.Identity?.Name ?? "Administrator";
        await db.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO audit.AccountAdministrationLog(AccountId, PreviousStatus, NewStatus, Reason, ChangedBy) VALUES({accountId},{previousStatus},{request.Status},{request.Reason.Trim()},{changedBy})");
        return Ok(new { account.AccountId, account.Status });
    }

    [HttpGet("accounts")]
    public async Task<IActionResult> GetAccounts() => Ok(await (
        from account in db.Accounts.AsNoTracking()
        join customer in db.Customers.AsNoTracking() on account.CustomerId equals customer.CustomerId
        orderby account.AccountNumber
        select new { account.AccountId, account.AccountNumber, account.Currency, account.Status,
            CustomerName = customer.FirstName + " " + customer.LastName, customer.Email }
    ).Take(300).ToListAsync());

    [HttpPost("accounts/{accountId:long}/cash-accounts")]
    public async Task<IActionResult> OpenCashAccount(long accountId, AdminOpenCashAccountRequest request)
    {
        var currency = request.Currency.Trim().ToUpperInvariant();
        if (!await db.Accounts.AnyAsync(item => item.AccountId == accountId)) return NotFound();
        var validCurrency = await db.Database.SqlQuery<int>($"SELECT COUNT(1) AS Value FROM core.Currency WHERE CurrencyCode = {currency}").SingleAsync() > 0;
        if (!validCurrency) return BadRequest(new ProblemDetails { Detail = "Moneda selectată nu este disponibilă." });
        if (await db.CashAccounts.AnyAsync(item => item.AccountId == accountId && item.Currency == currency)) return Conflict(new ProblemDetails { Detail = "Contul de numerar există deja." });
        var cash = new CashAccount { AccountId = accountId, Currency = currency, AvailableBalance = 0, BlockedBalance = 0 };
        db.CashAccounts.Add(cash); await db.SaveChangesAsync();
        return Ok(new { cash.CashAccountId, cash.Currency });
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers() => Ok(await db.ApiUsers.AsNoTracking()
        .Where(item => item.Role == "Broker" || item.Role == "Administrator")
        .OrderBy(item => item.Role).ThenBy(item => item.Email)
        .Select(item => new { item.ApiUserId, item.Email, item.Role, item.IsActive, item.CreatedAt })
        .ToListAsync());

    [HttpPost("users/{userId:guid}/status")]
    public async Task<IActionResult> UpdateUserStatus(Guid userId, UserStatusRequest request)
    {
        var user = await db.ApiUsers.FindAsync(userId);
        if (user is null || user.Role == "Customer") return NotFound();
        user.IsActive = request.IsActive;
        await db.SaveChangesAsync();
        await AuditAsync(user, request.IsActive ? "Activated" : "Deactivated", user.Email, null);
        return Ok(new { user.ApiUserId, user.IsActive });
    }

    [HttpPost("users/{userId:guid}/reset-password")]
    public async Task<IActionResult> ResetPassword(Guid userId, ResetPasswordRequest request)
    {
        if (request.NewPassword.Length < 8) return BadRequest(new ProblemDetails { Detail = "Parola trebuie să conțină cel puțin 8 caractere." });
        var user = await db.ApiUsers.FindAsync(userId);
        if (user is null || user.Role == "Customer") return NotFound();
        user.PasswordHash = passwordHasher.HashPassword(user, request.NewPassword);
        await db.SaveChangesAsync();
        await AuditAsync(user, "PasswordReset", user.Email, null);
        return NoContent();
    }

    [HttpPost("users/{userId:guid}/sign-out-all")]
    public async Task<IActionResult> SignOutAllSessions(Guid userId)
    {
        var user = await db.ApiUsers.FindAsync(userId);
        if (user is null || user.Role == "Customer") return NotFound();
        user.SessionVersion++;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
        await AuditAsync(user, "SignedOutAllSessions", user.Email, "Toate sesiunile active au fost invalidate.");
        return NoContent();
    }

    [HttpGet("access-audit")]
    public async Task<IActionResult> GetAccessAudit() => Ok(await db.Database.SqlQuery<AccessAuditEntry>($"SELECT TOP 200 AccessAuditLogId, Action, TargetEmail, Details, ChangedBy, ChangedAt FROM audit.AccessAuditLog ORDER BY ChangedAt DESC").ToListAsync());

    [HttpGet("sessions")]
    public async Task<IActionResult> GetRecentStaffSessions() => Ok(await db.Database.SqlQuery<AdminSessionEntry>($"""
        SELECT TOP 100 sessionHistory.UserSessionHistoryId, userAccount.Email, userAccount.Role,
               sessionHistory.DeviceInfo, sessionHistory.IpAddress, sessionHistory.LoggedInAt
        FROM audit.UserSessionHistory AS sessionHistory
        INNER JOIN security.ApiUser AS userAccount ON userAccount.ApiUserId = sessionHistory.ApiUserId
        WHERE userAccount.Role IN ('Broker', 'Administrator')
        ORDER BY sessionHistory.LoggedInAt DESC
        """).ToListAsync());

    [HttpGet("order-audit")]
    public async Task<IActionResult> GetOrderAudit() => Ok(await db.Database.SqlQuery<OrderAuditEntry>($"""
        SELECT TOP 500 OrderActivityLogId, OrderId, Activity, Details, ChangedBy, ChangedAt
        FROM audit.OrderActivityLog ORDER BY ChangedAt DESC
        """).ToListAsync());

    private Task AuditAsync(ApiUser user, string action, string email, string? details)
    {
        var changedBy = User.Identity?.Name ?? "Administrator";
        return db.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO audit.AccessAuditLog(ApiUserId, Action, TargetEmail, Details, ChangedBy) VALUES({user.ApiUserId},{action},{email},{details},{changedBy})");
    }
}

public record AccountStatusRequest(string Status, string? Reason);
public record UserStatusRequest(bool IsActive);
public record ResetPasswordRequest(string NewPassword);
public record AdminOpenCashAccountRequest(string Currency);
public record CreateStaffUserRequest(string Email, string Password, string Role);
public record AccessAuditEntry(long AccessAuditLogId, string Action, string TargetEmail, string? Details, string ChangedBy, DateTime ChangedAt);
public record AdminSessionEntry(long UserSessionHistoryId, string Email, string Role, string? DeviceInfo, string? IpAddress, DateTime LoggedInAt);
public record OrderAuditEntry(long OrderActivityLogId, long? OrderId, string Activity, string? Details, string ChangedBy, DateTime ChangedAt);
