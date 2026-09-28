using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/profile")]
public class ProfileController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        if (IsStaff()) return Forbid();
        if (!long.TryParse(User.FindFirstValue("customerId"), out var customerId)) return Forbid();

        var profile = await (
            from customer in db.Customers.AsNoTracking()
            join kyc in db.KycRecords.AsNoTracking() on customer.CustomerId equals kyc.CustomerId into kycGroup
            from kyc in kycGroup.DefaultIfEmpty()
            where customer.CustomerId == customerId
            select new
            {
                customer.FirstName,
                customer.LastName,
                customer.Email,
                CustomerStatus = customer.Status,
                KycStatus = kyc == null ? "Missing" : kyc.Status,
                DocumentType = kyc == null ? null : kyc.DocumentType,
                KycCreatedAt = kyc == null ? (DateTime?)null : kyc.CreatedAt,
                kyc!.VerifiedAt,
                kyc!.RejectionReason
            }).SingleOrDefaultAsync();

        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpGet("sessions")]
    public async Task<IActionResult> GetSessions()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userId, out var id)) return Forbid();
        return Ok(await db.Database.SqlQuery<SessionEntry>($"SELECT TOP 10 UserSessionHistoryId, DeviceInfo, IpAddress, LoggedInAt FROM audit.UserSessionHistory WHERE ApiUserId={id} ORDER BY LoggedInAt DESC").ToListAsync());
    }

    private bool IsStaff() => User.IsInRole("Broker")
        || User.IsInRole("ComplianceOfficer")
        || User.IsInRole("Administrator");
}
public record SessionEntry(long UserSessionHistoryId, string? DeviceInfo, string? IpAddress, DateTime LoggedInAt);
