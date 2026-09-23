namespace Brokerage.Api.DTOs.Accounts;

public record PortfolioValuation(decimal InvestedValueEUR, decimal PositionsValueEUR, decimal CashValueEUR, decimal TotalValueEUR, decimal ProfitLossEUR, decimal ProfitLossPercent, DateTime ValuationDate, string PriceSource);
