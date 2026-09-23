using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Services;

public class DevelopmentUserSeeder(
    BrokerageDbContext db,
    IPasswordHasher<ApiUser> passwordHasher,
    ILogger<DevelopmentUserSeeder> logger)
{
    public async Task SeedAsync()
    {
        var customer = await db.Customers
            .AsNoTracking()
            .SingleOrDefaultAsync(item => item.Email == "alex.popescu@example.test");

        if (customer is null)
        {
            logger.LogWarning("Utilizatorii demonstrativi nu au fost creați deoarece clientul de test lipsește.");
            return;
        }

        await CreateIfMissingAsync(
            "customer.demo@brokerage.local",
            "DemoCustomer!2026",
            "Customer",
            customer.CustomerId);

        await CreateIfMissingAsync(
            "broker.demo@brokerage.local",
            "DemoBroker!2026",
            "Broker",
            null);

        await CreateIfMissingAsync(
            "admin.demo@brokerage.local",
            "DemoAdmin!2026",
            "Administrator",
            null);

        await db.SaveChangesAsync();
    }

    private async Task CreateIfMissingAsync(
        string email,
        string password,
        string role,
        long? customerId)
    {
        if (await db.ApiUsers.AnyAsync(item => item.Email == email))
            return;

        var user = new ApiUser
        {
            ApiUserId = Guid.NewGuid(),
            Email = email,
            Role = role,
            CustomerId = customerId,
            IsActive = true
        };

        user.PasswordHash = passwordHasher.HashPassword(user, password);
        db.ApiUsers.Add(user);
    }
}
