USE BrokerageDB;
GO

/* Test autonom al fluxului. Toate datele de test sunt anulate prin rollback. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY
    DECLARE
        @CustomerId BIGINT,
        @AccountId BIGINT,
        @CashAccountId BIGINT,
        @InstrumentId BIGINT,
        @OrderId BIGINT;

    SELECT TOP (1) @InstrumentId = InstrumentId
    FROM trading.Instrument
    WHERE Currency = 'USD' AND IsActive = 1
    ORDER BY InstrumentId;

    INSERT INTO core.Customer
        (CustomerTypeId, FirstName, LastName, Email, Status)
    VALUES
        (1, 'Workflow', 'Test',
         CONCAT('workflow.', CONVERT(VARCHAR(36), NEWID()), '@example.test'),
         'Active');
    SET @CustomerId = SCOPE_IDENTITY();

    INSERT INTO core.KYC
        (CustomerId, Status, DocumentType, VerifiedAt, VerifiedBy)
    VALUES
        (@CustomerId, 'Approved', 'IdentityCard', SYSUTCDATETIME(),
         'workflow-test');

    INSERT INTO core.Account
        (CustomerId, AccountNumber, Currency, Status)
    VALUES
        (@CustomerId, CONCAT('TEST-', RIGHT(CONVERT(VARCHAR(36), NEWID()), 12)),
         'USD', 'Active');
    SET @AccountId = SCOPE_IDENTITY();

    INSERT INTO core.CashAccount
        (AccountId, Currency, AvailableBalance, BlockedBalance)
    VALUES (@AccountId, 'USD', 0, 0);
    SET @CashAccountId = SCOPE_IDENTITY();

    EXEC trading.usp_DepositCash @CashAccountId, 2000, 'Workflow test';

    DECLARE @CreatedOrder TABLE (OrderId BIGINT, Status VARCHAR(20));
    INSERT INTO @CreatedOrder
    EXEC trading.usp_CreateOrder
        @AccountId = @AccountId,
        @InstrumentId = @InstrumentId,
        @Side = 'BUY',
        @OrderType = 'LIMIT',
        @Quantity = 10,
        @LimitPrice = 100;

    SELECT @OrderId = OrderId FROM @CreatedOrder;

    EXEC trading.usp_ExecuteOrder
        @OrderId = @OrderId,
        @ExecutedQuantity = 10,
        @ExecutionPrice = 99;

    IF NOT EXISTS
    (
        SELECT 1 FROM trading.[Order]
        WHERE OrderId = @OrderId AND Status = 'Executed'
    )
        THROW 54002, N'Ordinul nu a ajuns în starea Executed.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM trading.Position
        WHERE AccountId = @AccountId
          AND InstrumentId = @InstrumentId
          AND Quantity = 10
          AND AveragePrice = 99
    )
        THROW 54003, N'Poziția nu a fost creată corect.', 1;

    IF (SELECT COUNT(*) FROM trading.Execution WHERE OrderId = @OrderId) <> 1
        THROW 54004, N'Era așteptată exact o execuție.', 1;

    IF (SELECT COUNT(*) FROM trading.Commission c
        INNER JOIN trading.Execution e ON e.ExecutionId = c.ExecutionId
        WHERE e.OrderId = @OrderId) <> 1
        THROW 54005, N'Era așteptat exact un comision.', 1;

    IF (SELECT COUNT(*) FROM audit.OrderStatusHistory
        WHERE OrderId = @OrderId
          AND OldStatus = 'Pending'
          AND NewStatus = 'Executed') <> 1
        THROW 54006, N'Istoricul stării ordinului este incomplet.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM audit.AuditLog
        WHERE TableName = 'trading.Execution'
          AND Action = 'INSERT'
    )
        THROW 54007, N'Înregistrarea de audit pentru execuție lipsește.', 1;

    ROLLBACK TRANSACTION;
    PRINT N'TESTUL #15 A TRECUT - fluxul complet de tranzacționare funcționează.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
