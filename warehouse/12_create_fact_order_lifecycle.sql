USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* DW #12 - un rând pentru fiecare ordin și starea sa curentă. */
IF OBJECT_ID('dw.FactOrderLifecycle', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactOrderLifecycle
    (
        OrderLifecycleKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CreatedDateKey INT NOT NULL REFERENCES dw.DimDate(DateKey),
        ResolutionDateKey INT NULL REFERENCES dw.DimDate(DateKey),
        CustomerKey INT NOT NULL REFERENCES dw.DimCustomer(CustomerKey),
        AccountKey INT NOT NULL REFERENCES dw.DimAccount(AccountKey),
        InstrumentKey INT NOT NULL REFERENCES dw.DimInstrument(InstrumentKey),
        OrderId BIGINT NOT NULL UNIQUE,
        Side VARCHAR(4) NOT NULL,
        OrderType VARCHAR(10) NOT NULL,
        OrderStatus VARCHAR(20) NOT NULL,
        OrderedQuantity DECIMAL(19,8) NOT NULL,
        ExecutedQuantity DECIMAL(19,8) NOT NULL,
        RemainingQuantity AS (OrderedQuantity - ExecutedQuantity) PERSISTED,
        ExecutionCount INT NOT NULL,
        LimitPrice DECIMAL(19,8) NULL,
        CreatedAt DATETIME2(3) NOT NULL,
        ResolvedAt DATETIME2(3) NULL,
        ResolutionMinutes INT NULL,
        RejectionReason VARCHAR(500) NULL,
        DWCreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_FactOrderLifecycle_Quantity CHECK
            (OrderedQuantity > 0 AND ExecutedQuantity >= 0 AND ExecutedQuantity <= OrderedQuantity)
    );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dw.FactOrderLifecycle') AND name = 'IX_FactOrderLifecycle_Customer_Status_Date')
    CREATE INDEX IX_FactOrderLifecycle_Customer_Status_Date
        ON dw.FactOrderLifecycle(CustomerKey, OrderStatus, CreatedDateKey)
        INCLUDE (AccountKey, InstrumentKey, OrderedQuantity, ExecutedQuantity, ResolutionMinutes);
GO
