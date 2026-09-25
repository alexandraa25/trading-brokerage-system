USE BrokerageDB;
GO

IF COL_LENGTH('trading.[Order]', 'StopPrice') IS NULL
    ALTER TABLE trading.[Order] ADD StopPrice DECIMAL(19,8) NULL;
GO

DECLARE @constraint sysname;
DECLARE @sql nvarchar(500);
SELECT @constraint = name FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID('trading.[Order]') AND definition LIKE '%OrderType%MARKET%LIMIT%';
IF @constraint IS NOT NULL
BEGIN
    SET @sql = N'ALTER TABLE trading.[Order] DROP CONSTRAINT ' + QUOTENAME(@constraint) + N';';
    EXEC sys.sp_executesql @sql;
END;
ALTER TABLE trading.[Order] ADD CONSTRAINT CK_Order_OrderType_Advanced CHECK (OrderType IN ('MARKET','LIMIT','STOP','STOP_LIMIT'));
GO

CREATE OR ALTER PROCEDURE trading.usp_CancelOrderPartially
    @OrderId BIGINT,
    @CancelledQuantity DECIMAL(19,8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ordered DECIMAL(19,8), @Executed DECIMAL(19,8), @Remaining DECIMAL(19,8);
    SELECT @Ordered=Quantity FROM trading.[Order] WITH(UPDLOCK,HOLDLOCK) WHERE OrderId=@OrderId AND Status IN('Pending','PartiallyExecuted');
    IF @Ordered IS NULL THROW 50042,N'Ordinul nu poate fi anulat.',1;
    SELECT @Executed=ISNULL(SUM(ExecutedQuantity),0) FROM trading.Execution WHERE OrderId=@OrderId;
    SET @Remaining=@Ordered-@Executed;
    IF @CancelledQuantity<=0 OR @CancelledQuantity>@Remaining THROW 50043,N'Cantitatea de anulat trebuie să fie între zero și cantitatea rămasă.',1;
    UPDATE trading.[Order] SET Quantity=Quantity-@CancelledQuantity,Status=CASE WHEN Quantity-@CancelledQuantity<=@Executed THEN 'Cancelled' ELSE Status END,UpdatedAt=SYSUTCDATETIME() WHERE OrderId=@OrderId;
    SELECT @OrderId OrderId, @CancelledQuantity CancelledQuantity, @Remaining-@CancelledQuantity RemainingQuantity;
END;
GO
