using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace Brokerage.Api.Tests;

public class ApiAuthorizationTests(BrokerageApiFactory factory) : IClassFixture<BrokerageApiFactory>
{
    private async Task<HttpClient> ClientFor(string email)
    {
        var client = factory.CreateClient();
        var login = await client.PostAsJsonAsync("/api/auth/login", new { email, password = "TestPass!2026" });
        login.EnsureSuccessStatusCode();
        var token = (await login.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("token").GetString();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task Autentificare_valida_returneaza_rolul_si_identitatea()
    {
        using var client = await ClientFor("client@test.local");
        var me = await client.GetFromJsonAsync<JsonElement>("/api/auth/me");
        Assert.Equal("Customer", me.GetProperty("role").GetString());
        Assert.Equal(BrokerageApiFactory.CustomerId, me.GetProperty("customerId").GetInt64());
    }

    [Fact]
    public async Task Clientul_nu_are_acces_la_endpointurile_broker_si_administrator()
    {
        using var client = await ClientFor("client@test.local");
        Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync("/api/broker/executions")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await client.GetAsync("/api/admin/overview")).StatusCode);
    }

    [Fact]
    public async Task Clientul_nu_poate_modifica_soldul_altui_client()
    {
        using var client = await ClientFor("client@test.local");
        var response = await client.PostAsJsonAsync($"/api/cash-accounts/{BrokerageApiFactory.OtherCashAccountId}/deposits", new { amount = 50m, description = "test" });
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Ordinul_invalid_este_respins_inainte_de_executie()
    {
        using var client = await ClientFor("client@test.local");
        var response = await client.PostAsJsonAsync("/api/orders", new { accountId = BrokerageApiFactory.AccountId, instrumentId = 401, side = "BUY", orderType = "LIMIT", quantity = 1m, limitPrice = (decimal?)null });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Brokerul_poate_citi_executiile_dar_clientul_nu_poate_executa_ordine()
    {
        using var broker = await ClientFor("broker@test.local");
        Assert.Equal(HttpStatusCode.OK, (await broker.GetAsync("/api/broker/executions")).StatusCode);
        using var customer = await ClientFor("client@test.local");
        Assert.Equal(HttpStatusCode.Forbidden, (await customer.PostAsJsonAsync("/api/orders/999/executions", new { executedQuantity = 1m, executionPrice = 10m })).StatusCode);
    }

    [Fact]
    public async Task Administratorul_poate_vedea_KYC_si_utilizatorii()
    {
        using var admin = await ClientFor("admin@test.local");
        Assert.Equal(HttpStatusCode.OK, (await admin.GetAsync("/api/admin/kyc")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await admin.GetAsync("/api/admin/users")).StatusCode);
    }
}
