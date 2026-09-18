USE BrokerageDB;
GO

-- Inspect existent test orders

SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt
FROM trading.[Order]
ORDER BY OrderId;
GO

SELECT
    OrderStatusHistoryId,
    OrderId,
    OldStatus,
    NewStatus,
    ChangedBy,
    ChangedAt
FROM audit.OrderStatusHistory
ORDER BY ChangedAt;
GO
