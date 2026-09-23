USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   DW #9 - Încarcă FactCashTransaction

   Sursă: BrokerageDB.staging.CashTransaction
   Strategie: incrementală și idempotentă după CashTransactionId.
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @RowsInserted BIGINT = 0;
DECLARE @RowsUpdated BIGINT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('tempdb..#SourceCashFact') IS NOT NULL
        DROP TABLE #SourceCashFact;

    SELECT
        CONVERT(INT, CONVERT(CHAR(8), CAST(cash_transaction.CreatedAt AS DATE), 112)) AS DateKey,
        CONVERT
        (
            INT,
            CONVERT
            (
                CHAR(8),
                COALESCE
                (
                    CASE
                        WHEN cash_transaction.Currency = 'EUR' THEN CAST(cash_transaction.CreatedAt AS DATE)
                        WHEN conversion.CurrencyConversionId IS NOT NULL
                         AND cash_transaction.CashAccountId = conversion.SourceCashAccountId
                            THEN conversion.SourceRateDate
                        WHEN conversion.CurrencyConversionId IS NOT NULL
                         AND cash_transaction.CashAccountId = conversion.TargetCashAccountId
                            THEN conversion.TargetRateDate
                        ELSE latest_rate.RateDate
                    END,
                    CAST(cash_transaction.CreatedAt AS DATE)
                ),
                112
            )
        ) AS ExchangeRateDateKey,
        customer.CustomerKey,
        account.AccountKey,
        currency.CurrencyKey,
        cash_transaction.CashTransactionId,
        cash_transaction.CashAccountId,
        cash_transaction.TransactionType,
        cash_transaction.ReferenceType,
        cash_transaction.ReferenceId,
        cash_transaction.Amount AS AmountOriginal,
        CAST
        (
            CASE
                WHEN cash_transaction.Currency = 'EUR' THEN 1
                WHEN conversion.CurrencyConversionId IS NOT NULL
                 AND cash_transaction.CashAccountId = conversion.SourceCashAccountId
                    THEN conversion.SourceRateToEur
                WHEN conversion.CurrencyConversionId IS NOT NULL
                 AND cash_transaction.CashAccountId = conversion.TargetCashAccountId
                    THEN conversion.TargetRateToEur
                ELSE latest_rate.MidRate
            END
            AS DECIMAL(19,10)
        ) AS ExchangeRateToEur,
        CAST
        (
            CASE
                WHEN cash_transaction.Currency = 'EUR' THEN 'IDENTITY_EUR'
                WHEN conversion.CurrencyConversionId IS NOT NULL THEN conversion.RateSource
                ELSE latest_rate.SourceSystem
            END
            AS VARCHAR(50)
        ) AS ExchangeRateSource,
        CAST
        (
            cash_transaction.Amount
            * CASE
                WHEN cash_transaction.Currency = 'EUR' THEN 1
                WHEN conversion.CurrencyConversionId IS NOT NULL
                 AND cash_transaction.CashAccountId = conversion.SourceCashAccountId
                    THEN conversion.SourceRateToEur
                WHEN conversion.CurrencyConversionId IS NOT NULL
                 AND cash_transaction.CashAccountId = conversion.TargetCashAccountId
                    THEN conversion.TargetRateToEur
                ELSE latest_rate.MidRate
              END
            AS DECIMAL(19,4)
        ) AS AmountEur,
        cash_transaction.CreatedAt
    INTO #SourceCashFact
    FROM BrokerageDB.staging.CashTransaction AS cash_transaction
    INNER JOIN BrokerageDB.core.CashAccount AS cash_account
        ON cash_account.CashAccountId = cash_transaction.CashAccountId
    INNER JOIN dw.DimAccount AS account
        ON account.AccountId = cash_account.AccountId
    INNER JOIN dw.DimCustomer AS customer
        ON customer.CustomerId = account.CustomerId
    INNER JOIN dw.DimCurrency AS currency
        ON currency.CurrencyCode = cash_transaction.Currency
    LEFT JOIN BrokerageDB.trading.CurrencyConversion AS conversion
        ON cash_transaction.ReferenceType = 'CurrencyConversion'
       AND cash_transaction.ReferenceId = conversion.CurrencyConversionId
    OUTER APPLY
    (
        SELECT TOP (1)
            rate_row.RateDate,
            rate_row.MidRate,
            rate_row.SourceSystem
        FROM BrokerageDB.core.ExchangeRate AS rate_row
        WHERE rate_row.SourceCurrency = cash_transaction.Currency
          AND rate_row.TargetCurrency = 'EUR'
          AND rate_row.RateDate <= CAST(cash_transaction.CreatedAt AS DATE)
        ORDER BY rate_row.RateDate DESC
    ) AS latest_rate;

    IF EXISTS
    (
        SELECT 1
        FROM #SourceCashFact
        WHERE ExchangeRateToEur IS NULL
           OR ExchangeRateSource IS NULL
    )
        THROW 54030, N'Lipsește cursul istoric către EUR pentru una sau mai multe mișcări de numerar.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM #SourceCashFact AS source_row
        LEFT JOIN dw.DimDate AS transaction_date
            ON transaction_date.DateKey = source_row.DateKey
        LEFT JOIN dw.DimDate AS rate_date
            ON rate_date.DateKey = source_row.ExchangeRateDateKey
        WHERE transaction_date.DateKey IS NULL
           OR rate_date.DateKey IS NULL
    )
        THROW 54031, N'Calendarul dimensional nu acoperă toate mișcările de numerar sau datele cursurilor.', 1;

    UPDATE target
    SET
        DateKey = source_row.DateKey,
        ExchangeRateDateKey = source_row.ExchangeRateDateKey,
        CustomerKey = source_row.CustomerKey,
        AccountKey = source_row.AccountKey,
        CurrencyKey = source_row.CurrencyKey,
        CashAccountId = source_row.CashAccountId,
        TransactionType = source_row.TransactionType,
        ReferenceType = source_row.ReferenceType,
        ReferenceId = source_row.ReferenceId,
        AmountOriginal = source_row.AmountOriginal,
        ExchangeRateToEur = source_row.ExchangeRateToEur,
        ExchangeRateSource = source_row.ExchangeRateSource,
        AmountEur = source_row.AmountEur,
        CreatedAt = source_row.CreatedAt,
        DWUpdatedAt = SYSUTCDATETIME()
    FROM dw.FactCashTransaction AS target
    INNER JOIN #SourceCashFact AS source_row
        ON source_row.CashTransactionId = target.CashTransactionId
    WHERE target.DateKey <> source_row.DateKey
       OR target.ExchangeRateDateKey <> source_row.ExchangeRateDateKey
       OR target.CustomerKey <> source_row.CustomerKey
       OR target.AccountKey <> source_row.AccountKey
       OR target.CurrencyKey <> source_row.CurrencyKey
       OR target.CashAccountId <> source_row.CashAccountId
       OR target.TransactionType <> source_row.TransactionType
       OR ISNULL(target.ReferenceType, '') <> ISNULL(source_row.ReferenceType, '')
       OR ISNULL(target.ReferenceId, -1) <> ISNULL(source_row.ReferenceId, -1)
       OR target.AmountOriginal <> source_row.AmountOriginal
       OR target.ExchangeRateToEur <> source_row.ExchangeRateToEur
       OR target.ExchangeRateSource <> source_row.ExchangeRateSource
       OR target.AmountEur <> source_row.AmountEur
       OR target.CreatedAt <> source_row.CreatedAt;

    SET @RowsUpdated = @@ROWCOUNT;

    INSERT INTO dw.FactCashTransaction
    (
        DateKey, ExchangeRateDateKey, CustomerKey, AccountKey, CurrencyKey,
        CashTransactionId, CashAccountId, TransactionType, ReferenceType, ReferenceId,
        AmountOriginal, ExchangeRateToEur, ExchangeRateSource, AmountEur, CreatedAt
    )
    SELECT
        DateKey, ExchangeRateDateKey, CustomerKey, AccountKey, CurrencyKey,
        CashTransactionId, CashAccountId, TransactionType, ReferenceType, ReferenceId,
        AmountOriginal, ExchangeRateToEur, ExchangeRateSource, AmountEur, CreatedAt
    FROM #SourceCashFact AS source_row
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.FactCashTransaction AS target
        WHERE target.CashTransactionId = source_row.CashTransactionId
    );

    SET @RowsInserted = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT N'Încărcarea FactCashTransaction s-a finalizat cu succes.';
    PRINT CONCAT('Rânduri inserate: ', @RowsInserted, N'; rânduri actualizate: ', @RowsUpdated, N'.');
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
