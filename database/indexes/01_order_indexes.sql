USE BrokerageDB;
GO

CREATE INDEX IX_Order_AccountId_CreatedAt
ON trading.[Order](AccountId, CreatedAt DESC);
GO

CREATE INDEX IX_Order_InstrumentId_Status
ON trading.[Order](InstrumentId, Status)
INCLUDE
(
    AccountId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    CreatedAt
);
GO

CREATE INDEX IX_Order_AccountId_Status_CreatedAt
ON trading.[Order](AccountId, Status, CreatedAt DESC)
INCLUDE
(
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice
);
GO

CREATE INDEX IX_Order_Status_CreatedAt
ON trading.[Order](Status, CreatedAt DESC)
INCLUDE
(
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice
);
GO

CREATE INDEX IX_CashTransaction_CashAccountId_CreatedAt
ON trading.CashTransaction(CashAccountId, CreatedAt DESC)
INCLUDE
(
    TransactionType,
    Amount,
    Currency,
    ReferenceType,
    ReferenceId
);
GO

CREATE INDEX IX_Execution_OrderId_ExecutedAt
ON trading.Execution(OrderId, ExecutedAt DESC)
INCLUDE
(
    ExecutedQuantity,
    ExecutionPrice
);
GO
