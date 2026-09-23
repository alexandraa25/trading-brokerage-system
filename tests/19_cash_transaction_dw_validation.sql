USE BrokerageDW;
GO

/* Verificări read-only pentru factul mișcărilor de numerar. */

SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM dw.FactCashTransaction) <>
   (SELECT COUNT(*) FROM BrokerageDB.staging.CashTransaction)
    THROW 55010, N'Numărul faptelor de numerar diferă de zona staging.', 1;

IF EXISTS
(
    SELECT CashTransactionId
    FROM dw.FactCashTransaction
    GROUP BY CashTransactionId
    HAVING COUNT(*) > 1
)
    THROW 55011, N'FactCashTransaction conține tranzacții de numerar duplicate.', 1;

IF EXISTS
(
    SELECT 1
    FROM dw.FactCashTransaction
    WHERE ExchangeRateToEur <= 0
       OR ExchangeRateSource IS NULL
       OR AmountOriginal = 0
)
    THROW 55012, N'FactCashTransaction conține cursuri sau sume nevalide.', 1;

IF EXISTS
(
    SELECT 1
    FROM dw.FactCashTransaction AS fact
    LEFT JOIN dw.DimCustomer AS customer ON customer.CustomerKey = fact.CustomerKey
    LEFT JOIN dw.DimAccount AS account ON account.AccountKey = fact.AccountKey
    LEFT JOIN dw.DimCurrency AS currency ON currency.CurrencyKey = fact.CurrencyKey
    LEFT JOIN dw.DimDate AS transaction_date ON transaction_date.DateKey = fact.DateKey
    LEFT JOIN dw.DimDate AS rate_date ON rate_date.DateKey = fact.ExchangeRateDateKey
    WHERE customer.CustomerKey IS NULL
       OR account.AccountKey IS NULL
       OR currency.CurrencyKey IS NULL
       OR transaction_date.DateKey IS NULL
       OR rate_date.DateKey IS NULL
)
    THROW 55013, N'FactCashTransaction conține referințe dimensionale invalide.', 1;

IF EXISTS
(
    SELECT 1
    FROM BrokerageDB.staging.CashTransaction AS source_row
    LEFT JOIN dw.FactCashTransaction AS fact
        ON fact.CashTransactionId = source_row.CashTransactionId
    WHERE fact.CashTransactionId IS NULL
       OR fact.AmountOriginal <> source_row.Amount
)
    THROW 55014, N'Sumele originale din FactCashTransaction nu corespund sursei.', 1;

SELECT
    fact.TransactionType,
    currency.CurrencyCode,
    COUNT(*) AS NumarMiscari,
    SUM(fact.AmountOriginal) AS SumaOriginala,
    SUM(fact.AmountEur) AS SumaEur
FROM dw.FactCashTransaction AS fact
INNER JOIN dw.DimCurrency AS currency
    ON currency.CurrencyKey = fact.CurrencyKey
GROUP BY fact.TransactionType, currency.CurrencyCode
ORDER BY fact.TransactionType, currency.CurrencyCode;

PRINT N'Validarea FactCashTransaction s-a finalizat cu succes.';
GO
