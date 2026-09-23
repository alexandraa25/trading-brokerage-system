using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Brokerage.Api.Services;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Administrator,ComplianceOfficer")]
[ApiController]
[Route("api/admin/kyc")]
public class AdminKycController(BrokerageDbContext db, CustomerNotificationService notifications) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetKycRecords() => Ok(await (
        from kyc in db.KycRecords.AsNoTracking()
        join customer in db.Customers.AsNoTracking() on kyc.CustomerId equals customer.CustomerId
        orderby kyc.UpdatedAt descending
        select new { kyc.KycId, kyc.CustomerId, customer.FirstName, customer.LastName, customer.Email, CustomerStatus = customer.Status, kyc.Status, kyc.DocumentType, kyc.CreatedAt, kyc.UpdatedAt, kyc.RejectionReason }
    ).Take(100).ToListAsync());

    [HttpGet("audit")]
    public async Task<IActionResult> GetKycAudit() => Ok(await db.Database.SqlQuery<KycAuditEntry>($"""
        SELECT TOP (100) AuditLogId, Action, ChangedBy, ChangedAt, OldValues, NewValues
        FROM audit.AuditLog
        WHERE TableName = 'core.KYC'
        ORDER BY ChangedAt DESC, AuditLogId DESC
        """).ToListAsync());

    [HttpPost("{kycId:long}/status")]
    public async Task<IActionResult> UpdateStatus(long kycId, [FromBody] KycStatusRequest request)
    {
        if (request.Status is not ("Approved" or "Rejected")) return BadRequest(new ProblemDetails { Detail = "Status KYC invalid." });
        var kyc = await db.KycRecords.SingleOrDefaultAsync(item => item.KycId == kycId);
        if (kyc is null) return NotFound();
        kyc.Status = request.Status; kyc.VerifiedAt = DateTime.UtcNow; kyc.VerifiedBy = User.Identity?.Name ?? "Administrator"; kyc.RejectionReason = request.Status == "Rejected" ? request.RejectionReason : null; kyc.UpdatedAt = DateTime.UtcNow;
        if (request.Status == "Rejected")
            await db.Accounts.Where(account => account.CustomerId == kyc.CustomerId && account.Status == "Active")
                .ExecuteUpdateAsync(setter => setter.SetProperty(account => account.Status, "Suspended"));
        await db.SaveChangesAsync();
        var title = request.Status == "Approved" ? "Verificare KYC aprobată" : "Verificare KYC respinsă";
        var message = request.Status == "Approved"
            ? "Dosarul tău KYC a fost aprobat. Poți folosi toate operațiunile disponibile."
            : $"Dosarul tău KYC a fost respins. Motiv: {request.RejectionReason ?? "nespecificat"}.";
        await notifications.CreateAsync(kyc.CustomerId, "Kyc", title, message);
        return Ok(new { kyc.KycId, kyc.Status });
    }
}

public record KycStatusRequest(string Status, string? RejectionReason);
public record KycAuditEntry(long AuditLogId, string Action, string ChangedBy, DateTime ChangedAt, string? OldValues, string? NewValues);
