using System.ComponentModel.DataAnnotations;

namespace Brokerage.Api.DTOs.Executions;

public class ExecuteOrderRequest
{
    [Range(typeof(decimal), "0.00000001", "99999999999")]
    public decimal ExecutedQuantity { get; init; }

    [Range(typeof(decimal), "0.00000001", "99999999999")]
    public decimal ExecutionPrice { get; init; }
}

public record ExecutionResult(
    long OrderId,
    long ExecutionId,
    decimal ExecutedQuantity,
    decimal ExecutionPrice,
    decimal TradeValue,
    decimal CommissionAmount,
    string Currency,
    decimal ExchangeRateToEur,
    DateTime ExchangeRateDate,
    string ExchangeRateSource,
    decimal TradeValueEur,
    decimal CommissionEur,
    string ReportingCurrency,
    string NewOrderStatus);
