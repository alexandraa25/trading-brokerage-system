/* Decizia brokerului și motivul respingerii ordinului. */
IF OBJECT_ID('audit.OrderDecision', 'U') IS NULL
BEGIN
    CREATE TABLE audit.OrderDecision
    (
        OrderDecisionId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_OrderDecision PRIMARY KEY,
        OrderId BIGINT NOT NULL CONSTRAINT FK_OrderDecision_Order FOREIGN KEY REFERENCES trading.[Order](OrderId),
        Decision VARCHAR(20) NOT NULL,
        Reason VARCHAR(500) NOT NULL,
        DecidedBy VARCHAR(100) NOT NULL,
        DecidedAt DATETIME2(3) NOT NULL CONSTRAINT DF_OrderDecision_DecidedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_OrderDecision_Decision CHECK (Decision IN ('Rejected'))
    );
END;
GO

CREATE OR ALTER PROCEDURE trading.usp_RejectOrder
    @OrderId BIGINT,
    @Reason VARCHAR(500),
    @DecidedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF NULLIF(LTRIM(RTRIM(@Reason)), '') IS NULL
        THROW 50051, N'Motivul respingerii este obligatoriu.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @CurrentStatus VARCHAR(20);
        SELECT @CurrentStatus = Status FROM trading.[Order] WITH (UPDLOCK, HOLDLOCK) WHERE OrderId = @OrderId;
        IF @CurrentStatus IS NULL THROW 50052, N'Ordinul nu există.', 1;
        IF @CurrentStatus NOT IN ('Pending', 'PartiallyExecuted')
            THROW 50053, N'Poate fi respins doar un ordin în așteptare sau parțial executat.', 1;

        UPDATE trading.[Order] SET Status = 'Rejected', UpdatedAt = SYSUTCDATETIME() WHERE OrderId = @OrderId;
        INSERT INTO audit.OrderDecision (OrderId, Decision, Reason, DecidedBy)
        VALUES (@OrderId, 'Rejected', @Reason, @DecidedBy);
        COMMIT TRANSACTION;
        SELECT @OrderId AS OrderId, 'Rejected' AS Status;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
