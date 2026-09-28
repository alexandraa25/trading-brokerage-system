using Xunit;
using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Brokerage.Api.Tests;

public sealed class BrokerageApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly SqliteConnection connection = new("Data Source=:memory:");
    public const long CustomerId = 101;
    public const long OtherCustomerId = 102;
    public const long AccountId = 201;
    public const long OtherAccountId = 202;
    public const long CashAccountId = 301;
    public const long OtherCashAccountId = 302;
    public BrokerageApiFactory()
    {
        Environment.SetEnvironmentVariable("Jwt__Key", "test-key-for-brokerage-api-that-is-long-enough-2026");
        Environment.SetEnvironmentVariable("Jwt__Issuer", "Brokerage.Api.Tests");
        Environment.SetEnvironmentVariable("Jwt__Audience", "Brokerage.Api.Tests");
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureLogging(logging => logging.ClearProviders());
        builder.ConfigureAppConfiguration(config => config.AddInMemoryCollection(new Dictionary<string, string?> {
            ["Jwt:Key"] = "test-key-for-brokerage-api-that-is-long-enough-2026",
            ["Jwt:Issuer"] = "Brokerage.Api.Tests", ["Jwt:Audience"] = "Brokerage.Api.Tests"
        }));
        builder.ConfigureServices(services => {
            services.RemoveAll<BrokerageDbContext>();
            services.RemoveAll<DbContextOptions<BrokerageDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<BrokerageDbContext>>();
            services.AddDbContext<BrokerageDbContext>(options => options.UseSqlite(connection));
        });
    }

    public async Task InitializeAsync()
    {
        await connection.OpenAsync();
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<BrokerageDbContext>();
        await db.Database.EnsureCreatedAsync();
        await db.Database.ExecuteSqlRawAsync("ATTACH DATABASE ':memory:' AS trading;");
        await db.Database.ExecuteSqlRawAsync("ATTACH DATABASE ':memory:' AS audit;");
        await db.Database.ExecuteSqlRawAsync("CREATE TABLE trading.MarketQuote (InstrumentId INTEGER NOT NULL, MarketPrice REAL NOT NULL, QuoteDate TEXT NOT NULL);");
        await db.Database.ExecuteSqlRawAsync("INSERT INTO trading.MarketQuote (InstrumentId, MarketPrice, QuoteDate) VALUES (401, 100, '2026-09-28T00:00:00Z');");
        await db.Database.ExecuteSqlRawAsync("CREATE TABLE audit.UserSessionHistory (UserSessionHistoryId INTEGER PRIMARY KEY AUTOINCREMENT, ApiUserId TEXT NOT NULL, DeviceInfo TEXT NULL, IpAddress TEXT NULL, LoggedInAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);");
        await db.Database.ExecuteSqlRawAsync("CREATE TABLE audit.AccessAuditLog (AccessAuditLogId INTEGER PRIMARY KEY AUTOINCREMENT, ApiUserId TEXT NOT NULL, Action TEXT NOT NULL, TargetEmail TEXT NOT NULL, Details TEXT NULL, ChangedBy TEXT NOT NULL, ChangedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);");
        await db.Database.ExecuteSqlRawAsync("CREATE TABLE audit.OrderActivityLog (OrderActivityLogId INTEGER PRIMARY KEY AUTOINCREMENT, OrderId INTEGER NULL, Activity TEXT NOT NULL, Details TEXT NULL, ChangedBy TEXT NOT NULL, ChangedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);");
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher<ApiUser>>();
        var now = DateTime.UtcNow;
        ApiUser User(string email, string role, long? customerId = null) { var user = new ApiUser { ApiUserId = Guid.NewGuid(), Email = email, Role = role, CustomerId = customerId, IsActive = true, CreatedAt = now, UpdatedAt = now }; user.PasswordHash = hasher.HashPassword(user, "TestPass!2026"); return user; }
        db.ApiUsers.AddRange(User("client@test.local", "Customer", CustomerId), User("broker@test.local", "Broker"), User("admin@test.local", "Administrator"));
        db.Customers.AddRange(new Customer { CustomerId = CustomerId, CustomerTypeId = 1, FirstName = "Client", LastName = "Test", Email = "client@test.local", Status = "Active" }, new Customer { CustomerId = OtherCustomerId, CustomerTypeId = 1, FirstName = "Alt", LastName = "Client", Email = "other@test.local", Status = "Active" });
        db.Accounts.AddRange(new TradingAccount { AccountId = AccountId, CustomerId = CustomerId, AccountNumber = "TEST-201", Currency = "EUR", Status = "Active", CreatedAt = now }, new TradingAccount { AccountId = OtherAccountId, CustomerId = OtherCustomerId, AccountNumber = "TEST-202", Currency = "EUR", Status = "Active", CreatedAt = now });
        db.CashAccounts.AddRange(new CashAccount { CashAccountId = CashAccountId, AccountId = AccountId, Currency = "EUR", AvailableBalance = 1000 }, new CashAccount { CashAccountId = OtherCashAccountId, AccountId = OtherAccountId, Currency = "EUR", AvailableBalance = 1000 });
        db.Instruments.Add(new Instrument { InstrumentId = 401, Symbol = "TEST", InstrumentName = "Instrument test", InstrumentType = "Stock", Currency = "EUR", IsActive = true });
        db.KycRecords.Add(new KycRecord { KycId = 501, CustomerId = CustomerId, Status = "Pending", DocumentType = "Carte de identitate", CreatedAt = now, UpdatedAt = now });
        await db.SaveChangesAsync();
    }

    async Task IAsyncLifetime.DisposeAsync() => await connection.DisposeAsync();
}
