using System.Security.Claims;
using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Customer")]
[ApiController]
[Route("api/customer-ai")]
public class CustomerAiController(CustomerAiService customerAiService) : ControllerBase
{
    [HttpPost("ask")]
    public async Task<IActionResult> Ask([FromBody] CustomerAiQuestion request, CancellationToken cancellationToken)
    {
        if (!long.TryParse(User.FindFirstValue("customerId"), out var customerId)) return Forbid();
        var question = request.Question?.Trim();
        if (string.IsNullOrWhiteSpace(question) || question.Length is < 5 or > 500) return BadRequest(new { detail = "Întrebarea trebuie să conțină între 5 și 500 de caractere." });
        try { return Ok(await customerAiService.AskAsync(customerId, question, cancellationToken)); }
        catch (AiNotConfiguredException) { return Problem("Asistentul AI nu este configurat pe server. Adaugă Groq:ApiKey în User Secrets.", statusCode: StatusCodes.Status503ServiceUnavailable); }
        catch (AiProviderException exception) { return Problem(exception.Message, statusCode: StatusCodes.Status502BadGateway); }
    }
}

public sealed record CustomerAiQuestion(string? Question);
