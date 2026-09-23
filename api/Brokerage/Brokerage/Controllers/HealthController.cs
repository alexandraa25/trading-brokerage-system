using Brokerage.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    private readonly BrokerageDbContext _db;

    public HealthController(BrokerageDbContext db)
    {
        _db = db;
    }

    [HttpGet("database")]
    [Microsoft.AspNetCore.Authorization.AllowAnonymous]
    public async Task<IActionResult> Database()
    {
        var canConnect = await _db.Database.CanConnectAsync();

        if (!canConnect)
        {
            return StatusCode(
                StatusCodes.Status503ServiceUnavailable,
                new
                {
                    database = "BrokerageDB",
                    status = "Unavailable"
                });
        }

        return Ok(new
        {
            database = "BrokerageDB",
            status = "Connected"
        });
    }
}
