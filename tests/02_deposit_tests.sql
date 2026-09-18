USE BrokerageDB;
GO

DECLARE @CashAccountId BIGINT = 1;
DECLARE @Before DECIMAL(19,4);
DECLARE @After DECIMAL(19,4);

SELECT @Before = AvailableBalance
FROM core.CashAccount
WHERE CashAccountId = @CashAccountId;

EXEC trading.usp_DepositCash
    @CashAccountId = @CashAccountId,
    @Amount = 1000.00,
    @Description = 'Deposit test';

SELECT @After = AvailableBalance
FROM core.CashAccount
WHERE CashAccountId = @CashAccountId;

SELECT
    @Before AS BalanceBefore,
    @After AS BalanceAfter,
    @After - @Before AS Difference;
GO



BEGIN TRY

    EXEC trading.usp_DepositCash
        @CashAccountId = 1,
        @Amount = -100;

    THROW 51001, N'Eroarea așteptată nu a fost produsă.', 1;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO
