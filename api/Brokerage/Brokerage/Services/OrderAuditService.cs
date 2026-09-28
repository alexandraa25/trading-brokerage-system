using Brokerage.Api.Data;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Services;

public sealed class OrderAuditService(BrokerageDbContext db, ILogger<OrderAuditService> logger)
{
    public async Task LogAsync(long? orderId, string activity, string details, string changedBy)
    {
        try
        {
            await db.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO audit.OrderActivityLog(OrderId, Activity, Details, ChangedBy) VALUES({orderId},{activity},{details},{changedBy})");
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception, "Auditul ordinului nu a putut fi salvat. Verifică scriptul database/22_security_activity_audit.sql.");
        }
    }
}
