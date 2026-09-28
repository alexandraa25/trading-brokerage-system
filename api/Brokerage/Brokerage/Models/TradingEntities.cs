namespace Brokerage.Api.Models;

public class Customer
{
    public long CustomerId { get; set; }
    public byte CustomerTypeId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

public class KycRecord
{
    public long KycId { get; set; }
    public long CustomerId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? DocumentType { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public string? VerifiedBy { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class TradingAccount
{
    public long AccountId { get; set; }
    public long CustomerId { get; set; }
    public string AccountNumber { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ClosedAt { get; set; }
}

public class CashAccount
{
    public long CashAccountId { get; set; }
    public long AccountId { get; set; }
    public string Currency { get; set; } = string.Empty;
    public decimal AvailableBalance { get; set; }
    public decimal BlockedBalance { get; set; }
}

public class Instrument
{
    public long InstrumentId { get; set; }
    public string Symbol { get; set; } = string.Empty;
    public string InstrumentName { get; set; } = string.Empty;
    public string InstrumentType { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class TradeOrder
{
    public long OrderId { get; set; }
    public long AccountId { get; set; }
    public long InstrumentId { get; set; }
    public string Side { get; set; } = string.Empty;
    public string OrderType { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal? OriginalQuantity { get; set; }
    public decimal CancelledQuantity { get; set; }
    public decimal? LimitPrice { get; set; }
    public decimal? StopPrice { get; set; }
    public string TimeInForce { get; set; } = "GTC";
    public DateTime? ExpiresAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class Position
{
    public long PositionId { get; set; }
    public long AccountId { get; set; }
    public long InstrumentId { get; set; }
    public decimal Quantity { get; set; }
    public decimal AveragePrice { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class TradeExecution
{
    public long ExecutionId { get; set; }
    public long OrderId { get; set; }
    public decimal ExecutedQuantity { get; set; }
    public decimal ExecutionPrice { get; set; }
    public DateTime ExecutedAt { get; set; }
    public string TradeCurrency { get; set; } = string.Empty;
    public string ReportingCurrency { get; set; } = string.Empty;
    public decimal ExchangeRateToReporting { get; set; }
    public DateTime ExchangeRateDate { get; set; }
    public string ExchangeRateSource { get; set; } = string.Empty;
    public decimal TradeValueReporting { get; set; }
    public decimal CommissionReporting { get; set; }
}

public class CashTransaction
{
    public long CashTransactionId { get; set; }
    public long CashAccountId { get; set; }
    public string TransactionType { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public long? ReferenceId { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CustomerNotification
{
    public long CustomerNotificationId { get; set; }
    public long CustomerId { get; set; }
    public string NotificationType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BrokerNotification
{
    public long BrokerNotificationId { get; set; }
    public string NotificationType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}
public class CustomerWatchlist { public long CustomerWatchlistId { get; set; } public long CustomerId { get; set; } public long InstrumentId { get; set; } public DateTime CreatedAt { get; set; } }
public class CustomerPriceAlert { public long CustomerPriceAlertId { get; set; } public long CustomerId { get; set; } public long InstrumentId { get; set; } public string Direction { get; set; } = string.Empty; public decimal TargetPrice { get; set; } public bool IsActive { get; set; } public DateTime? TriggeredAt { get; set; } public DateTime CreatedAt { get; set; } }
