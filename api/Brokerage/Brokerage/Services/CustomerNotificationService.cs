using Brokerage.Api.Data;
using Brokerage.Api.Models;

namespace Brokerage.Api.Services;

public class CustomerNotificationService(BrokerageDbContext db)
{
    public async Task CreateAsync(long customerId, string type, string title, string message)
    {
        db.CustomerNotifications.Add(new CustomerNotification
        {
            CustomerId = customerId,
            NotificationType = type,
            Title = title,
            Message = message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
    }
}
