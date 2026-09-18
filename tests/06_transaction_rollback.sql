USE BrokerageDB;
GO

/*
Test: Tranzacție Revenire - Insuficient Numerar

Rezultat așteptat:
- usp_ExecuteOrder raises an insuficient numerar eroare
- Soldul de numerar rămâne neschimbat
- No execuție is created
- Ordinul rămâne Pending
*/

-- Înainte state
SELECT
    CashAccountId,
    AccountId,
    Currency,
    AvailableBalance,
    BlockedBalance
FROM core.CashAccount
WHERE CashAccountId = 8;

SELECT
    COUNT(*) AS ExecutionCount
FROM trading.Execution
WHERE OrderId = 7;

SELECT
    OrderId,
    Status
FROM trading.[Order]
WHERE OrderId = 7;


-- Execute ordin intentionally fără sufficient numerar
BEGIN TRY

    EXEC trading.usp_ExecuteOrder
        @OrderId = 7,
        @ExecutedQuantity = 30.00000000,
        @ExecutionPrice = 102.00000000;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


-- După state
SELECT
    CashAccountId,
    AccountId,
    Currency,
    AvailableBalance,
    BlockedBalance
FROM core.CashAccount
WHERE CashAccountId = 8;

SELECT
    COUNT(*) AS ExecutionCount
FROM trading.Execution
WHERE OrderId = 7;

SELECT
    OrderId,
    Status
FROM trading.[Order]
WHERE OrderId = 7;
GO


