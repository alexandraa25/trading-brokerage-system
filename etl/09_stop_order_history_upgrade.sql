USE BrokerageDB;
GO

/* Migrare pentru staging existent; rulează după database/20_order_history_quantities.sql. */
IF COL_LENGTH('staging.[Order]', 'StopPrice') IS NULL
    ALTER TABLE staging.[Order] ADD StopPrice DECIMAL(19,8) NULL;
IF COL_LENGTH('staging.[Order]', 'OriginalQuantity') IS NULL
    ALTER TABLE staging.[Order] ADD OriginalQuantity DECIMAL(19,8) NULL;
IF COL_LENGTH('staging.[Order]', 'CancelledQuantity') IS NULL
    ALTER TABLE staging.[Order] ADD CancelledQuantity DECIMAL(19,8) NOT NULL CONSTRAINT DF_StagingOrder_CancelledQuantity DEFAULT (0);
GO

UPDATE target
SET StopPrice = source.StopPrice,
    OriginalQuantity = source.OriginalQuantity,
    CancelledQuantity = source.CancelledQuantity,
    Quantity = source.Quantity,
    Status = source.Status,
    UpdatedAt = source.UpdatedAt,
    ExtractedAt = SYSUTCDATETIME()
FROM staging.[Order] target
INNER JOIN trading.[Order] source ON source.OrderId = target.OrderId;
GO
