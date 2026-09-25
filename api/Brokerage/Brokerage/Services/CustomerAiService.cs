using System.Net.Http.Headers;
using System.Text.Json;
using Brokerage.Api.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Brokerage.Api.Services;

public sealed class CustomerAiService(BrokerageDbContext db, IConfiguration configuration, HttpClient httpClient)
{
    private const string Instructions = """
        Ești asistentul de informare pentru un client al unei aplicații demonstrative de brokeraj.
        Răspunde în română și explică numai datele personale agregate din context.
        Poți explica profitul/pierderea, structura portofoliului și impactul cursurilor BCE asupra afișării în EUR.
        Nu inventa date, nu recomanda cumpărarea sau vânzarea instrumentelor și nu promite rezultate financiare.
        Răspunde concis, cu secțiunile: Explicație, Date folosite, De reținut.
        """;

    public async Task<AdminAiAnswer> AskAsync(long customerId, string question, CancellationToken cancellationToken)
    {
        var apiKey = configuration["Groq:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey)) throw new AiNotConfiguredException();

        var context = await LoadContextAsync(customerId, cancellationToken);
        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.groq.com/openai/v1/chat/completions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = JsonContent.Create(new
        {
            model = configuration["Groq:Model"] ?? "openai/gpt-oss-20b",
            messages = new[] { new { role = "system", content = Instructions }, new { role = "user", content = $"Datele clientului:\n{context}\n\nÎntrebare: {question}" } },
            temperature = 0.2,
            max_completion_tokens = 600
        });

        using var response = await httpClient.SendAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode) throw new AiProviderException(BuildProviderMessage((int)response.StatusCode, body));
        var answer = ExtractAnswer(body);
        if (string.IsNullOrWhiteSpace(answer)) throw new AiProviderException("Serviciul AI a răspuns fără text analizabil. Încearcă din nou.");
        return new AdminAiAnswer(answer, DateTime.UtcNow, "Explicație informativă bazată pe datele portofoliului; nu reprezintă consultanță financiară.");
    }

    private async Task<string> LoadContextAsync(long customerId, CancellationToken cancellationToken)
    {
        var accountIds = await db.Accounts.AsNoTracking().Where(x => x.CustomerId == customerId).Select(x => x.AccountId).ToListAsync(cancellationToken);
        var cash = await db.CashAccounts.AsNoTracking().Where(x => accountIds.Contains(x.AccountId)).GroupBy(x => x.Currency).Select(x => new { Currency = x.Key, Available = x.Sum(i => i.AvailableBalance), Blocked = x.Sum(i => i.BlockedBalance) }).OrderBy(x => x.Currency).ToListAsync(cancellationToken);
        var positions = await (from position in db.Positions.AsNoTracking()
                               join instrument in db.Instruments.AsNoTracking() on position.InstrumentId equals instrument.InstrumentId
                               where accountIds.Contains(position.AccountId) && position.Quantity > 0
                               group new { position, instrument } by instrument.Currency into groupValue
                               select new { Currency = groupValue.Key, Invested = groupValue.Sum(x => x.position.Quantity * x.position.AveragePrice), Positions = groupValue.Count() }).ToListAsync(cancellationToken);

        var rates = new List<string>();
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = "SELECT SourceCurrency, MidRate, RateDate FROM (SELECT SourceCurrency, MidRate, RateDate, ROW_NUMBER() OVER(PARTITION BY SourceCurrency ORDER BY RateDate DESC) AS rowNumber FROM core.ExchangeRate WHERE TargetCurrency='EUR') rate WHERE rowNumber=1 ORDER BY SourceCurrency";
        await db.Database.OpenConnectionAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken)) rates.Add($"{reader.GetString(0)} → EUR: {reader.GetDecimal(1):N6}, data {reader.GetDateTime(2):yyyy-MM-dd}");

        return $"""
            - Număr conturi de tranzacționare: {accountIds.Count}
            - Solduri disponibile/blocate: {string.Join("; ", cash.Select(x => $"{x.Currency} {x.Available:N2}/{x.Blocked:N2}"))}
            - Poziții și valoare investită la preț mediu: {string.Join("; ", positions.Select(x => $"{x.Currency}: {x.Positions} poziții, {x.Invested:N2}"))}
            - Cursuri BCE curente către EUR: {string.Join("; ", rates)}
            """;
    }

    private static string? ExtractAnswer(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;
        return root.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0 && choices[0].TryGetProperty("message", out var message) && message.TryGetProperty("content", out var content) ? content.GetString() : null;
    }

    private static string BuildProviderMessage(int statusCode, string responseBody)
    {
        try { using var document = JsonDocument.Parse(responseBody); if (document.RootElement.TryGetProperty("error", out var error) && error.TryGetProperty("message", out var message) && !string.IsNullOrWhiteSpace(message.GetString())) return $"Serviciul AI a răspuns cu eroarea {statusCode}: {message.GetString()}"; }
        catch (JsonException) { }
        return $"Serviciul AI a răspuns cu eroarea {statusCode}. Verifică cheia, modelul și limita de utilizare configurate.";
    }
}
