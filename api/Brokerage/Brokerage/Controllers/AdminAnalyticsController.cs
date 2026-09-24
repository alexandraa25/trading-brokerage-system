using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Brokerage.Api.Controllers;

[Authorize(Roles = "Administrator")]
[ApiController]
[Route("api/admin/analytics")]
public class AdminAnalyticsController(IConfiguration configuration) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] int days = 30)
    {
        days = Math.Clamp(days, 7, 365);
        var connectionString = configuration.GetConnectionString("BrokerageDw")
            ?? throw new InvalidOperationException("Conexiunea la depozitul de date nu este configurată.");
        await using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        var portfolioValue = await ScalarDecimal(connection, "SELECT ISNULL(SUM(TotalValueEur),0) FROM dw.FactPortfolioDailySnapshot WHERE DateKey=(SELECT MAX(DateKey) FROM dw.FactPortfolioDailySnapshot)");
        var netCashFlow = await ScalarDecimal(connection, "SELECT ISNULL(SUM(AmountEur),0) FROM dw.FactCashTransaction");
        var commissions = await ScalarDecimal(connection, "SELECT ISNULL(SUM(CASE WHEN TransactionType='Commission' THEN -AmountEur ELSE 0 END),0) FROM dw.FactCashTransaction");
        var activeOrders = await ScalarInt(connection, "SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus IN ('Pending','PartiallyExecuted')");
        var completedOrders = await ScalarInt(connection, "SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus='Executed'");
        var rejectedOrders = await ScalarInt(connection, "SELECT COUNT(*) FROM dw.FactOrderLifecycle WHERE OrderStatus='Rejected'");
        var pendingKyc = await ScalarInt(connection, "SELECT COUNT(*) FROM dw.FactKyc WHERE KycStatus='Pending'");
        var averageKycDays = await ScalarDecimal(connection, "SELECT ISNULL(AVG(CAST(ResolutionDays AS DECIMAL(19,2))),0) FROM dw.FactKyc WHERE ResolutionDays IS NOT NULL");

        var trend = new List<object>();
        await using (var command = new SqlCommand("SELECT TOP (@days) CONVERT(varchar(10),Data,23), CAST(SUM(ValoareTotalaEur) AS decimal(19,2)) FROM dw.vwPowerBiPortfolioEvolution GROUP BY Data ORDER BY Data DESC", connection))
        {
            command.Parameters.AddWithValue("@days", days);
        await using (var reader = await command.ExecuteReaderAsync())
            while (await reader.ReadAsync()) trend.Add(new { date = reader.GetString(0), value = reader.GetDecimal(1) });
        }
        trend.Reverse();

        return Ok(new { portfolioValue, netCashFlow, commissions, activeOrders, completedOrders, rejectedOrders, pendingKyc, averageKycDays, trend, days });
    }

    private static async Task<decimal> ScalarDecimal(SqlConnection connection, string sql)
    {
        await using var command = new SqlCommand(sql, connection);
        return Convert.ToDecimal(await command.ExecuteScalarAsync());
    }
    private static async Task<int> ScalarInt(SqlConnection connection, string sql)
    {
        await using var command = new SqlCommand(sql, connection);
        return Convert.ToInt32(await command.ExecuteScalarAsync());
    }
}
