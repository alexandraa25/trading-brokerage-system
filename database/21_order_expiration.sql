USE BrokerageDB;
GO
IF COL_LENGTH('trading.[Order]', 'TimeInForce') IS NULL
    ALTER TABLE trading.[Order] ADD TimeInForce VARCHAR(10) NOT NULL CONSTRAINT DF_Order_TimeInForce DEFAULT ('GTC');
IF COL_LENGTH('trading.[Order]', 'ExpiresAt') IS NULL
    ALTER TABLE trading.[Order] ADD ExpiresAt DATETIME2(3) NULL;
GO
DECLARE @constraint sysname, @sql nvarchar(max);
SELECT TOP 1 @constraint=name FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('trading.[Order]') AND name LIKE 'CK_Order_Status%';
IF @constraint IS NOT NULL BEGIN SET @sql=N'ALTER TABLE trading.[Order] DROP CONSTRAINT '+QUOTENAME(@constraint)+';'; EXEC sys.sp_executesql @sql; END;
ALTER TABLE trading.[Order] ADD CONSTRAINT CK_Order_Status_Expiry CHECK (Status IN ('Pending','WaitingTrigger','Triggered','PartiallyExecuted','Executed','Cancelled','Rejected','Expired'));
GO
