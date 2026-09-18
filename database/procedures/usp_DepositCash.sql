USE BrokerageDB;
GO

CREATE OR ALTER PROCEDURE trading.usp_DepositCash
    @CashAccountId BIGINT,
    @Amount        DECIMAL(19,4),
    @Description   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Currency CHAR(3);

    BEGIN TRY

        IF @Amount <= 0
            THROW 50001, N'Suma depusă trebuie să fie mai mare decât zero.', 1;

        BEGIN TRANSACTION;

        SELECT @Currency = ca.Currency
        FROM core.CashAccount ca WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN core.Account a WITH (UPDLOCK, HOLDLOCK)
            ON a.AccountId = ca.AccountId
        INNER JOIN core.Customer c WITH (UPDLOCK, HOLDLOCK)
            ON c.CustomerId = a.CustomerId
        INNER JOIN core.KYC k WITH (UPDLOCK, HOLDLOCK)
            ON k.CustomerId = c.CustomerId
        WHERE ca.CashAccountId = @CashAccountId
          AND a.Status = 'Active'
          AND c.Status = 'Active'
          AND k.Status = 'Approved';

        IF @Currency IS NULL
            THROW 50002, N'Contul de numerar lipsește sau clientul nu este eligibil pentru depuneri.', 1;

        UPDATE core.CashAccount
        SET AvailableBalance = AvailableBalance + @Amount
        WHERE CashAccountId = @CashAccountId;

        INSERT INTO trading.CashTransaction
        (
            CashAccountId,
            TransactionType,
            Amount,
            Currency,
            ReferenceType,
            ReferenceId,
            Description
        )
        VALUES
        (
            @CashAccountId,
            'Deposit',
            @Amount,
            @Currency,
            'ManualDeposit',
            NULL,
            @Description
        );

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO
