USE BrokerageDW;
GO

/* Extinde FactOrderLifecycle pentru ordine DAY, DATE și GTC expirate. */
IF COL_LENGTH('dw.FactOrderLifecycle', 'TimeInForce') IS NULL
    ALTER TABLE dw.FactOrderLifecycle
        ADD TimeInForce VARCHAR(10) NOT NULL
            CONSTRAINT DF_FactOrderLifecycle_TimeInForce DEFAULT ('GTC');
GO
IF COL_LENGTH('dw.FactOrderLifecycle', 'ExpiresAt') IS NULL
    ALTER TABLE dw.FactOrderLifecycle ADD ExpiresAt DATETIME2(3) NULL;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactOrderLifecycle')
      AND name = 'IX_FactOrderLifecycle_Status_Expiry'
)
    CREATE INDEX IX_FactOrderLifecycle_Status_Expiry
        ON dw.FactOrderLifecycle(OrderStatus, ExpiresAt)
        INCLUDE (OrderType, TimeInForce, CustomerKey, InstrumentKey);
GO

PRINT N'FactOrderLifecycle include acum valabilitatea și expirarea ordinelor.';
GO
