using Brokerage.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Administrator")]
[ApiController]
[Route("api/admin/ai")]
public class AdminAiController(AdminAiService adminAiService) : ControllerBase
{
    [HttpPost("ask")]
    public async Task<IActionResult> Ask([FromBody] AdminAiQuestion request, CancellationToken cancellationToken)
    {
        var question = request.Question?.Trim();
        if (string.IsNullOrWhiteSpace(question) || question.Length is < 5 or > 500)
            return BadRequest(new { detail = "Întrebarea trebuie să conțină între 5 și 500 de caractere." });

        try
        {
            return Ok(await adminAiService.AskAsync(question, cancellationToken));
        }
        catch (AiNotConfiguredException)
        {
            return Problem("Asistentul AI nu este configurat pe server. Adaugă Groq:ApiKey în User Secrets.", statusCode: StatusCodes.Status503ServiceUnavailable);
        }
        catch (AiProviderException exception)
        {
            return Problem(exception.Message, statusCode: StatusCodes.Status502BadGateway);
        }
    }
}

public sealed record AdminAiQuestion(string? Question);
