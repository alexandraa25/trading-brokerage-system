USE BrokerageDB;
GO

/* Aduce staging-ul la structura ordinelor cu valabilitate și expirare. */
IF COL_LENGTH('staging.[Order]', 'TimeInForce') IS NULL
    ALTER TABLE staging.[Order]
        ADD TimeInForce VARCHAR(10) NOT NULL
            CONSTRAINT DF_StagingOrder_TimeInForce DEFAULT ('GTC');
GO
IF COL_LENGTH('staging.[Order]', 'ExpiresAt') IS NULL
    ALTER TABLE staging.[Order] ADD ExpiresAt DATETIME2(3) NULL;
GO

UPDATE target
SET TimeInForce = source.TimeInForce,
    ExpiresAt = source.ExpiresAt,
    ExtractedAt = SYSUTCDATETIME()
FROM staging.[Order] target
INNER JOIN trading.[Order] source ON source.OrderId = target.OrderId;
GO

PRINT N'Staging-ul include acum valabilitatea și data expirării ordinelor.';
GO
