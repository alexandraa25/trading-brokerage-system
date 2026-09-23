using Brokerage.Api.Data;
using Brokerage.Api.Models;

namespace Brokerage.Api.Services;

public class BrokerNotificationService(BrokerageDbContext db)
{
    public async Task CreateAsync(string type, string title, string message)
    {
        db.BrokerNotifications.Add(new BrokerNotification
        {
            NotificationType = type,
            Title = title,
            Message = message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
    }
}
