using Brokerage.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Data;

public class BrokerageDbContext(DbContextOptions<BrokerageDbContext> options)
    : DbContext(options)
{
    public DbSet<ApiUser> ApiUsers => Set<ApiUser>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<KycRecord> KycRecords => Set<KycRecord>();
    public DbSet<TradingAccount> Accounts => Set<TradingAccount>();
    public DbSet<CashAccount> CashAccounts => Set<CashAccount>();
    public DbSet<Instrument> Instruments => Set<Instrument>();
    public DbSet<TradeOrder> Orders => Set<TradeOrder>();
    public DbSet<Position> Positions => Set<Position>();
    public DbSet<TradeExecution> Executions => Set<TradeExecution>();
    public DbSet<CashTransaction> CashTransactions => Set<CashTransaction>();
    public DbSet<CustomerNotification> CustomerNotifications => Set<CustomerNotification>();
    public DbSet<BrokerNotification> BrokerNotifications => Set<BrokerNotification>();
    public DbSet<CustomerWatchlist> CustomerWatchlists => Set<CustomerWatchlist>();
    public DbSet<CustomerPriceAlert> CustomerPriceAlerts => Set<CustomerPriceAlert>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ApiUser>(entity =>
        {
            entity.ToTable("ApiUser", "security", table => table.HasTrigger("trg_ApiUser_Audit"));
            entity.HasKey(user => user.ApiUserId);
        });

        modelBuilder.Entity<Customer>(entity =>
        {
            entity.ToTable("Customer", "core", table => table.HasTrigger("trg_Customer_Audit"));
            entity.HasKey(customer => customer.CustomerId);
        });

        modelBuilder.Entity<KycRecord>(entity =>
        {
            entity.ToTable("KYC", "core", table => table.HasTrigger("trg_KYC_AuditLog"));
            entity.HasKey(record => record.KycId);
        });

        modelBuilder.Entity<TradingAccount>(entity =>
        {
            entity.ToTable("Account", "core", table => table.HasTrigger("trg_AccountAdministration_Audit"));
            entity.HasKey(account => account.AccountId);
        });

        modelBuilder.Entity<CashAccount>(entity =>
        {
            entity.ToTable("CashAccount", "core");
            entity.HasKey(account => account.CashAccountId);
            entity.Property(account => account.AvailableBalance).HasPrecision(19, 4);
            entity.Property(account => account.BlockedBalance).HasPrecision(19, 4);
        });

        modelBuilder.Entity<Instrument>(entity =>
        {
            entity.ToTable("Instrument", "trading");
            entity.HasKey(instrument => instrument.InstrumentId);
        });

        modelBuilder.Entity<TradeOrder>(entity =>
        {
            entity.ToTable("Order", "trading", table => table.HasTrigger("trg_Order_StatusHistory"));
            entity.HasKey(order => order.OrderId);
            entity.Property(order => order.Quantity).HasPrecision(19, 8);
            entity.Property(order => order.OriginalQuantity).HasPrecision(19, 8);
            entity.Property(order => order.CancelledQuantity).HasPrecision(19, 8);
            entity.Property(order => order.LimitPrice).HasPrecision(19, 8);
            entity.Property(order => order.StopPrice).HasPrecision(19, 8);
        });

        modelBuilder.Entity<Position>(entity =>
        {
            entity.ToTable("Position", "trading");
            entity.HasKey(position => position.PositionId);
            entity.Property(position => position.Quantity).HasPrecision(19, 8);
            entity.Property(position => position.AveragePrice).HasPrecision(19, 8);
        });

        modelBuilder.Entity<TradeExecution>(entity =>
        {
            entity.ToTable("Execution", "trading");
            entity.HasKey(execution => execution.ExecutionId);
            entity.Property(execution => execution.ExecutedQuantity).HasPrecision(19, 8);
            entity.Property(execution => execution.ExecutionPrice).HasPrecision(19, 8);
            entity.Property(execution => execution.ExchangeRateToReporting).HasPrecision(19, 10);
            entity.Property(execution => execution.TradeValueReporting).HasPrecision(19, 4);
            entity.Property(execution => execution.CommissionReporting).HasPrecision(19, 4);
        });

        modelBuilder.Entity<CashTransaction>(entity =>
        {
            entity.ToTable("CashTransaction", "trading");
            entity.HasKey(transaction => transaction.CashTransactionId);
            entity.Property(transaction => transaction.Amount).HasPrecision(19, 4);
        });

        modelBuilder.Entity<CustomerNotification>(entity =>
        {
            entity.ToTable("CustomerNotification", "core");
            entity.HasKey(notification => notification.CustomerNotificationId);
        });

        modelBuilder.Entity<BrokerNotification>(entity =>
        {
            entity.ToTable("BrokerNotification", "audit");
            entity.HasKey(notification => notification.BrokerNotificationId);
        });
        modelBuilder.Entity<CustomerWatchlist>(entity => { entity.ToTable("CustomerWatchlist", "core"); entity.HasKey(x => x.CustomerWatchlistId); });
        modelBuilder.Entity<CustomerPriceAlert>(entity => { entity.ToTable("CustomerPriceAlert", "core"); entity.HasKey(x => x.CustomerPriceAlertId); });
    }
}
