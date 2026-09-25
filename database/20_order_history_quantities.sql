USE BrokerageDB;
GO

IF COL_LENGTH('trading.[Order]', 'OriginalQuantity') IS NULL
    ALTER TABLE trading.[Order] ADD OriginalQuantity DECIMAL(19,8) NULL;
GO
IF COL_LENGTH('trading.[Order]', 'CancelledQuantity') IS NULL
    ALTER TABLE trading.[Order] ADD CancelledQuantity DECIMAL(19,8) NOT NULL CONSTRAINT DF_Order_CancelledQuantity DEFAULT (0);
GO

/* Ordinelor existente li se păstrează cantitatea inițială cunoscută. */
UPDATE trading.[Order]
SET OriginalQuantity = Quantity + CancelledQuantity
WHERE OriginalQuantity IS NULL;
GO

CREATE OR ALTER PROCEDURE trading.usp_CancelOrderPartially
    @OrderId BIGINT,
    @CancelledQuantity DECIMAL(19,8)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Ordered DECIMAL(19,8), @Executed DECIMAL(19,8), @Remaining DECIMAL(19,8);
    SELECT @Ordered=Quantity FROM trading.[Order] WITH(UPDLOCK,HOLDLOCK)
    WHERE OrderId=@OrderId AND Status IN('Pending','WaitingTrigger','Triggered','PartiallyExecuted');
    IF @Ordered IS NULL THROW 50042,N'Ordinul nu poate fi anulat.',1;
    SELECT @Executed=ISNULL(SUM(ExecutedQuantity),0) FROM trading.Execution WHERE OrderId=@OrderId;
    SET @Remaining=@Ordered-@Executed;
    IF @CancelledQuantity<=0 OR @CancelledQuantity>@Remaining THROW 50043,N'Cantitatea de anulat trebuie să fie între zero și cantitatea rămasă.',1;
    UPDATE trading.[Order]
    SET OriginalQuantity=COALESCE(OriginalQuantity, Quantity + CancelledQuantity),
        CancelledQuantity=CancelledQuantity+@CancelledQuantity,
        Quantity=Quantity-@CancelledQuantity,
        Status=CASE WHEN Quantity-@CancelledQuantity<=@Executed THEN 'Cancelled' ELSE Status END,
        UpdatedAt=SYSUTCDATETIME()
    WHERE OrderId=@OrderId;
    SELECT @OrderId OrderId, @CancelledQuantity CancelledQuantity, @Remaining-@CancelledQuantity RemainingQuantity;
END;
GO
