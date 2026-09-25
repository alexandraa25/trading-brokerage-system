using System.Security.Claims;
using Brokerage.Api.Data;
using Brokerage.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace Brokerage.Api.Controllers;
[Authorize(Roles="Customer")][ApiController][Route("api/market")]
public class MarketWatchlistController(BrokerageDbContext db):ControllerBase
{
 long CustomerId()=>long.Parse(User.FindFirstValue("customerId")!);
 [HttpGet("watchlist")] public async Task<IActionResult> Watchlist()=>Ok(await db.CustomerWatchlists.Where(x=>x.CustomerId==CustomerId()).Select(x=>x.InstrumentId).ToListAsync());
 [HttpPost("watchlist/{instrumentId:long}")] public async Task<IActionResult> Add(long instrumentId){var id=CustomerId();if(!await db.Instruments.AnyAsync(x=>x.InstrumentId==instrumentId&&x.IsActive))return NotFound();if(await db.CustomerWatchlists.AnyAsync(x=>x.CustomerId==id&&x.InstrumentId==instrumentId))return NoContent();db.CustomerWatchlists.Add(new CustomerWatchlist{CustomerId=id,InstrumentId=instrumentId});await db.SaveChangesAsync();return Ok();}
 [HttpDelete("watchlist/{instrumentId:long}")] public async Task<IActionResult> Remove(long instrumentId){var item=await db.CustomerWatchlists.SingleOrDefaultAsync(x=>x.CustomerId==CustomerId()&&x.InstrumentId==instrumentId);if(item is null)return NotFound();db.CustomerWatchlists.Remove(item);await db.SaveChangesAsync();return NoContent();}
 [HttpGet("price-alerts")] public async Task<IActionResult> Alerts()=>Ok(await (from alert in db.CustomerPriceAlerts where alert.CustomerId==CustomerId() join instrument in db.Instruments on alert.InstrumentId equals instrument.InstrumentId select new {alert.CustomerPriceAlertId, instrument.Symbol, alert.Direction, alert.TargetPrice, alert.IsActive, alert.TriggeredAt}).ToListAsync());
 [HttpPost("price-alerts")] public async Task<IActionResult> AddAlert(CreatePriceAlert request){if(request.Direction is not ("Above" or "Below")||request.TargetPrice<=0)return BadRequest(new ProblemDetails{Detail="Direcția și prețul țintă sunt obligatorii."});if(!await db.Instruments.AnyAsync(x=>x.InstrumentId==request.InstrumentId&&x.IsActive))return NotFound();db.CustomerPriceAlerts.Add(new CustomerPriceAlert{CustomerId=CustomerId(),InstrumentId=request.InstrumentId,Direction=request.Direction,TargetPrice=request.TargetPrice,IsActive=true});await db.SaveChangesAsync();return Ok();}
 [HttpDelete("price-alerts/{alertId:long}")] public async Task<IActionResult> DeleteAlert(long alertId){var item=await db.CustomerPriceAlerts.SingleOrDefaultAsync(x=>x.CustomerPriceAlertId==alertId&&x.CustomerId==CustomerId());if(item is null)return NotFound();db.CustomerPriceAlerts.Remove(item);await db.SaveChangesAsync();return NoContent();}
}
public record CreatePriceAlert(long InstrumentId,string Direction,decimal TargetPrice);
