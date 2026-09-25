using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace Brokerage.Api.Services;

public sealed class AdminAiService(IConfiguration configuration, HttpClient httpClient, ILogger<AdminAiService> logger)
{
    private const string Instructions = """
        Ești asistentul intern de analiză al unei aplicații demonstrative de brokeraj.
        Răspunde exclusiv în limba română, folosind numai indicatorii agregați furnizați în context.
        Nu inventa valori, nu presupune cauze care nu sunt susținute de date și menționează când datele lipsesc.
        Nu oferi recomandări financiare, nu recomanda cumpărarea sau vânzarea instrumentelor și nu lua decizii KYC.
        Răspunde concis, în trei secțiuni: Concluzie, Dovezi, Acțiune operațională sugerată.
        """;

    public async Task<AdminAiAnswer> AskAsync(string question, CancellationToken cancellationToken)
    {
        var apiKey = configuration["Groq:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
            throw new AiNotConfiguredException();

        var context = await LoadContextAsync(cancellationToken);
        var input = $"""
            Context agregat din BrokerageDW, generat la {DateTime.UtcNow:O}:
            {context}

            Întrebarea administratorului: {question}
            """;

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = JsonContent.Create(new
        {
            model = configuration["Groq:Model"] ?? "openai/gpt-oss-20b",
            messages = new[]
            {
                new { role = "system", content = Instructions },
                new { role = "user", content = input }
            },
            temperature = 0.2,
            max_completion_tokens = 700
        });

        using var response = await httpClient.SendAsync(request, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Serviciul AI a răspuns cu codul {StatusCode}.", (int)response.StatusCode);
            throw new AiProviderException(BuildProviderMessage((int)response.StatusCode, responseBody));
        }

        var answer = ExtractAnswer(responseBody);
        if (string.IsNullOrWhiteSpace(answer))
            throw new AiProviderException("Serviciul AI a răspuns fără text analizabil. Încearcă din nou.");

        return new AdminAiAnswer(answer, DateTime.UtcNow, "Analiză bazată pe date agregate din BrokerageDW; nu reprezintă consultanță financiară.");
    }

    private async Task<string> LoadContextAsync(CancellationToken cancellationToken)
    {
        var connectionString = configuration.GetConnectionString("BrokerageDw")
            ?? throw new InvalidOperationException("Conexiunea la depozitul de date nu este configurată.");
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync(cancellationToken);

        const string query = """
            SELECT
                ISNULL((SELECT SUM(TotalValueEur) FROM dw.FactPortfolioDailySnapshot WHERE DateKey = (SELECT MAX(DateKey) FROM dw.FactPortfolioDailySnapshot)), 0) AS PortfolioValueEur,
                ISNULL((SELECT SUM(AmountEur) FROM dw.FactCashTransaction), 0) AS NetCashFlowEur,
                ISNULL((SELECT SUM(CASE WHEN TransactionType = 'Commission' THEN -AmountEur ELSE 0 END) FROM dw.FactCashTransaction), 0) AS CommissionsEur,
                (SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus IN ('Pending', 'PartiallyExecuted')) AS ActiveOrders,
                (SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus = 'Executed') AS ExecutedOrders,
                (SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus = 'Rejected') AS RejectedOrders,
                (SELECT COUNT(*) FROM dw.FactKyc WHERE KycStatus = 'Pending') AS PendingKyc,
                ISNULL((SELECT AVG(CAST(ResolutionDays AS decimal(19,2))) FROM dw.FactKyc WHERE ResolutionDays IS NOT NULL), 0) AS AverageKycDays;
            """;

        await using var command = new SqlCommand(query, connection);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        await reader.ReadAsync(cancellationToken);
        return $"""
            - Valoare totală portofolii (EUR): {reader.GetDecimal(0):N2}
            - Flux net de numerar (EUR): {reader.GetDecimal(1):N2}
            - Comisioane (EUR): {reader.GetDecimal(2):N2}
            - Ordine active: {reader.GetInt32(3)}
            - Ordine executate: {reader.GetInt32(4)}
            - Ordine respinse: {reader.GetInt32(5)}
            - Dosare KYC în așteptare: {reader.GetInt32(6)}
            - Durata medie de soluționare KYC (zile): {reader.GetDecimal(7):N2}
            """;
    }

    private static string? ExtractAnswer(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        if (root.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0 &&
            choices[0].TryGetProperty("message", out var message) &&
            message.TryGetProperty("content", out var content)) return content.GetString();
        if (root.TryGetProperty("output_text", out var outputText)) return outputText.GetString();

        if (!root.TryGetProperty("output", out var output)) return null;
        foreach (var item in output.EnumerateArray())
        {
            if (!item.TryGetProperty("content", out var responseContent)) continue;
            foreach (var part in responseContent.EnumerateArray())
                if (part.TryGetProperty("type", out var type) && type.GetString() == "output_text" && part.TryGetProperty("text", out var text))
                    return text.GetString();
        }
        return null;
    }

    private static string BuildProviderMessage(int statusCode, string responseBody)
    {
        try
        {
            using var document = JsonDocument.Parse(responseBody);
            if (document.RootElement.TryGetProperty("error", out var error) &&
                error.TryGetProperty("message", out var message) &&
                !string.IsNullOrWhiteSpace(message.GetString()))
                return $"Serviciul AI a răspuns cu eroarea {statusCode}: {message.GetString()}";
        }
        catch (JsonException) { }

        return $"Serviciul AI a răspuns cu eroarea {statusCode}. Verifică cheia, modelul și limita de utilizare configurate.";
    }
}

public sealed record AdminAiAnswer(string Answer, DateTime GeneratedAtUtc, string Disclaimer);
public sealed class AiNotConfiguredException : Exception { }
public sealed class AiProviderException(string message) : Exception(message) { }
