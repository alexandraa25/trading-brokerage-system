namespace Brokerage.Api.DTOs.History;

public record ExecutionSummary(
    long ExecutionId,
    decimal ExecutedQuantity,
    decimal ExecutionPrice,
    DateTime ExecutedAt,
    string TradeCurrency,
    decimal ExchangeRateToEur,
    DateTime ExchangeRateDate,
    string ExchangeRateSource,
    decimal TradeValueEur,
    decimal CommissionEur);

public record CashTransactionSummary(
    long CashTransactionId,
    string TransactionType,
    decimal Amount,
    string Currency,
    string? ReferenceType,
    long? ReferenceId,
    string? Description,
    DateTime CreatedAt);
