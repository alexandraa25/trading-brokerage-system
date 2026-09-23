using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Brokerage.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public class NotificationsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetNotifications()
    {
        if (!TryGetCustomerId(out var customerId)) return Forbid();
        return Ok(await db.CustomerNotifications.AsNoTracking().Where(item => item.CustomerId == customerId)
            .OrderByDescending(item => item.CreatedAt).Take(50)
            .Select(item => new { item.CustomerNotificationId, item.NotificationType, item.Title, item.Message, item.IsRead, item.CreatedAt })
            .ToListAsync());
    }

    [HttpPost("{notificationId:long}/read")]
    public async Task<IActionResult> MarkRead(long notificationId)
    {
        if (!TryGetCustomerId(out var customerId)) return Forbid();
        var notification = await db.CustomerNotifications.SingleOrDefaultAsync(item => item.CustomerNotificationId == notificationId && item.CustomerId == customerId);
        if (notification is null) return NotFound();
        notification.IsRead = true;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        if (!TryGetCustomerId(out var customerId)) return Forbid();
        await db.CustomerNotifications.Where(item => item.CustomerId == customerId && !item.IsRead)
            .ExecuteUpdateAsync(setter => setter.SetProperty(item => item.IsRead, true));
        return NoContent();
    }

    private bool TryGetCustomerId(out long customerId) => long.TryParse(User.FindFirstValue("customerId"), out customerId)
        && !User.IsInRole("Broker") && !User.IsInRole("ComplianceOfficer") && !User.IsInRole("Administrator");
}
