using Brokerage.Api.Data;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Administrator")]
[ApiController]
[Route("api/admin/customers")]
public class AdminCustomersController(BrokerageDbContext db, CustomerNotificationService notifications) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetCustomers() => Ok(await (
        from customer in db.Customers.AsNoTracking()
        join kyc in db.KycRecords.AsNoTracking() on customer.CustomerId equals kyc.CustomerId into kycs
        from kyc in kycs.DefaultIfEmpty()
        orderby customer.Email
        select new CustomerAdminSummary(
            customer.CustomerId, customer.FirstName, customer.LastName, customer.Email, customer.Status,
            kyc == null ? "Lipsă" : kyc.Status,
            db.Accounts.Count(account => account.CustomerId == customer.CustomerId),
            db.Accounts.Where(account => account.CustomerId == customer.CustomerId).Select(account => account.Status).FirstOrDefault())
    ).Take(200).ToListAsync());

    [HttpPost("{customerId:long}/status")]
    public async Task<IActionResult> UpdateCustomerStatus(long customerId, CustomerStatusRequest request)
    {
        if (request.Status is not ("Active" or "Inactive" or "Blocked"))
            return BadRequest(new ProblemDetails { Detail = "Stare client invalidă." });
        var customer = await db.Customers.SingleOrDefaultAsync(item => item.CustomerId == customerId);
        if (customer is null) return NotFound();
        customer.Status = request.Status;
        await db.SaveChangesAsync();
        await notifications.CreateAsync(customer.CustomerId, "AccountStatus", "Starea profilului a fost actualizată",
            $"Profilul tău are acum starea: {request.Status}.");
        return Ok(new { customer.CustomerId, customer.Status });
    }

    [HttpGet("{customerId:long}/overview")]
    public async Task<IActionResult> GetCustomerOverview(long customerId)
    {
        var customer = await db.Customers.AsNoTracking().SingleOrDefaultAsync(item => item.CustomerId == customerId);
        if (customer is null) return NotFound();
        var accounts = await db.Accounts.AsNoTracking().Where(item => item.CustomerId == customerId)
            .Select(item => new { item.AccountId, item.AccountNumber, item.Currency, item.Status }).ToListAsync();
        var accountIds = accounts.Select(item => item.AccountId).ToArray();
        var cash = await db.CashAccounts.AsNoTracking().Where(item => accountIds.Contains(item.AccountId))
            .Select(item => new { item.AccountId, item.Currency, item.AvailableBalance, item.BlockedBalance }).ToListAsync();
        var positions = await (
            from position in db.Positions.AsNoTracking()
            join instrument in db.Instruments.AsNoTracking() on position.InstrumentId equals instrument.InstrumentId
            join account in db.Accounts.AsNoTracking() on position.AccountId equals account.AccountId
            where account.CustomerId == customerId && position.Quantity > 0
            select new { instrument.Symbol, instrument.Currency, position.Quantity, position.AveragePrice }
        ).ToListAsync();
        return Ok(new { customer.CustomerId, customer.FirstName, customer.LastName, customer.Email, customer.Status, Accounts = accounts, Cash = cash, Positions = positions });
    }
}

public record CustomerAdminSummary(long CustomerId, string FirstName, string LastName, string Email,
    string CustomerStatus, string KycStatus, int AccountsCount, string? AccountStatus);
public record CustomerStatusRequest(string Status);
