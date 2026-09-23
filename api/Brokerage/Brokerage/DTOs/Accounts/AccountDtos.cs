namespace Brokerage.Api.DTOs.Accounts;

public record AccountSummary(long AccountId, string AccountNumber, string Currency, string Status);
public record CashBalance(long CashAccountId, string Currency, decimal AvailableBalance, decimal BlockedBalance);
public record PortfolioPosition(string Symbol, string InstrumentName, string Currency, decimal Quantity, decimal AveragePrice, DateTime UpdatedAt);
