using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Services;

public sealed class StopOrderActivationService(IServiceScopeFactory scopeFactory, ILogger<StopOrderActivationService> logger)
    : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(30);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Interval);
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try { await ActivateEligibleOrdersAsync(stoppingToken); }
            catch (Exception exception) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(exception, "Nu au putut fi activate ordinele STOP.");
            }
        }
    }

    private async Task ActivateEligibleOrdersAsync(CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<BrokerageDbContext>();
        var notifications = scope.ServiceProvider.GetRequiredService<BrokerNotificationService>();

        var candidates = await (
            from order in db.Orders
            join instrument in db.Instruments on order.InstrumentId equals instrument.InstrumentId
            where (order.Status == "WaitingTrigger" || order.Status == "Pending")
               && (order.OrderType == "STOP" || order.OrderType == "STOP_LIMIT")
            select new { Order = order, instrument.Symbol }
        ).ToListAsync(cancellationToken);

        foreach (var candidate in candidates)
        {
            var quote = await db.Database.SqlQuery<StopOrderQuote>($"""
                SELECT TOP 1 MarketPrice, QuoteDate FROM trading.MarketQuote
                WHERE InstrumentId = {candidate.Order.InstrumentId} ORDER BY QuoteDate DESC
                """).SingleOrDefaultAsync(cancellationToken);
            if (quote is null || !candidate.Order.StopPrice.HasValue) continue;

            var reached = candidate.Order.Side == "BUY"
                ? quote.MarketPrice >= candidate.Order.StopPrice.Value
                : quote.MarketPrice <= candidate.Order.StopPrice.Value;
            if (!reached) continue;

            candidate.Order.Status = "Triggered";
            candidate.Order.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(cancellationToken);
            await notifications.CreateAsync("StopOrderTriggered", "Ordin STOP declanșat",
                $"Ordinul #{candidate.Order.OrderId} pentru {candidate.Symbol} a atins pragul {candidate.Order.StopPrice:0.####} și este pregătit pentru execuție.");
        }
    }
}

public record StopOrderQuote(decimal MarketPrice, DateTime QuoteDate);
