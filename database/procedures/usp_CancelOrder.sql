USE BrokerageDB;
GO

CREATE OR ALTER PROCEDURE trading.usp_CancelOrder
    @OrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus VARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @CurrentStatus = Status
        FROM trading.[Order] WITH (UPDLOCK, HOLDLOCK)
        WHERE OrderId = @OrderId;

        IF @CurrentStatus IS NULL
            THROW 50040, N'Ordinul nu există.', 1;

        IF @CurrentStatus NOT IN ('Pending', 'PartiallyExecuted')
            THROW 50041, N'Poate fi anulat doar un ordin în așteptare sau parțial executat.', 1;

        UPDATE trading.[Order]
        SET Status = 'Cancelled',
            UpdatedAt = SYSUTCDATETIME()
        WHERE OrderId = @OrderId;

        COMMIT TRANSACTION;

        SELECT @OrderId AS OrderId, 'Cancelled' AS Status;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
