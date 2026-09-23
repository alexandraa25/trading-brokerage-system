using Brokerage.Api.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Broker,Administrator")]
[ApiController]
[Route("api/broker/notifications")]
public class BrokerNotificationsController(BrokerageDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetNotifications() => Ok(await db.BrokerNotifications.AsNoTracking()
        .OrderByDescending(item => item.CreatedAt).Take(50)
        .Select(item => new { item.BrokerNotificationId, item.NotificationType, item.Title, item.Message, item.IsRead, item.CreatedAt })
        .ToListAsync());

    [HttpPost("{notificationId:long}/read")]
    public async Task<IActionResult> MarkRead(long notificationId)
    {
        var notification = await db.BrokerNotifications.FindAsync(notificationId);
        if (notification is null) return NotFound();
        notification.IsRead = true;
        await db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        await db.BrokerNotifications.Where(item => !item.IsRead)
            .ExecuteUpdateAsync(setter => setter.SetProperty(item => item.IsRead, true));
        return NoContent();
    }
}
