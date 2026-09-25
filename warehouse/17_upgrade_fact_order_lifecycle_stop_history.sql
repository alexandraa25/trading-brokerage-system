USE BrokerageDW;
GO

IF COL_LENGTH('dw.FactOrderLifecycle', 'CancelledQuantity') IS NULL
    ALTER TABLE dw.FactOrderLifecycle ADD CancelledQuantity DECIMAL(19,8) NOT NULL CONSTRAINT DF_FactOrderLifecycle_CancelledQuantity DEFAULT (0);
IF COL_LENGTH('dw.FactOrderLifecycle', 'StopPrice') IS NULL
    ALTER TABLE dw.FactOrderLifecycle ADD StopPrice DECIMAL(19,8) NULL;
IF COL_LENGTH('dw.FactOrderLifecycle', 'TriggeredAt') IS NULL
    ALTER TABLE dw.FactOrderLifecycle ADD TriggeredAt DATETIME2(3) NULL;
IF COL_LENGTH('dw.FactOrderLifecycle', 'TriggerDelayMinutes') IS NULL
    ALTER TABLE dw.FactOrderLifecycle ADD TriggerDelayMinutes INT NULL;
GO

DECLARE @constraint sysname, @sql nvarchar(max);
SELECT TOP 1 @constraint = name FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('dw.FactOrderLifecycle')
  AND name LIKE 'CK_FactOrderLifecycle_Quantity%';
IF @constraint IS NOT NULL
BEGIN
    SET @sql = N'ALTER TABLE dw.FactOrderLifecycle DROP CONSTRAINT ' + QUOTENAME(@constraint) + N';';
    EXEC sys.sp_executesql @sql;
END;
ALTER TABLE dw.FactOrderLifecycle ADD CONSTRAINT CK_FactOrderLifecycle_Quantity_Advanced
    CHECK (OrderedQuantity > 0 AND ExecutedQuantity >= 0 AND CancelledQuantity >= 0
       AND ExecutedQuantity + CancelledQuantity <= OrderedQuantity);
GO

/* Formula veche nu scădea cantitatea anulată. */
IF COL_LENGTH('dw.FactOrderLifecycle', 'RemainingQuantity') IS NOT NULL
    ALTER TABLE dw.FactOrderLifecycle DROP COLUMN RemainingQuantity;
ALTER TABLE dw.FactOrderLifecycle ADD RemainingQuantity AS (OrderedQuantity - ExecutedQuantity - CancelledQuantity) PERSISTED;
GO
