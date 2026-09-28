USE BrokerageDB;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   ETL #2 - Încărcarea inițială în staging

   Sursă:
       core / trading

   Destinație:
       staging

   Strategie:
       Reîncărcare completă
       TRUNCATE -> INSERT -> validare
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    BEGIN TRANSACTION;

    /* ========================================================
       1. Golește tabelele staging
       ======================================================== */

    TRUNCATE TABLE staging.Customer;
    TRUNCATE TABLE staging.Account;
    TRUNCATE TABLE staging.Market;
    TRUNCATE TABLE staging.Instrument;
    TRUNCATE TABLE staging.[Order];
    TRUNCATE TABLE staging.Execution;
    TRUNCATE TABLE staging.CashTransaction;


    /* ========================================================
       2. Încarcă Client
       ======================================================== */

    INSERT INTO staging.Customer
    (
        CustomerId,
        CustomerTypeId,
        FirstName,
        LastName,
        Email,
        Phone,
        DateOfBirth,
        Status,
        CreatedAt,
        UpdatedAt
    )
    SELECT
        CustomerId,
        CustomerTypeId,
        FirstName,
        LastName,
        Email,
        Phone,
        DateOfBirth,
        Status,
        CreatedAt,
        UpdatedAt
    FROM core.Customer;


    /* ========================================================
       3. Încarcă Cont
       ======================================================== */

    INSERT INTO staging.Account
    (
        AccountId,
        CustomerId,
        AccountNumber,
        Currency,
        Status,
        CreatedAt,
        UpdatedAt,
        ClosedAt
    )
    SELECT
        AccountId,
        CustomerId,
        AccountNumber,
        Currency,
        Status,
        CreatedAt,
        UpdatedAt,
        ClosedAt
    FROM core.Account;


    /* ========================================================
       4. Încarcă Market
       ======================================================== */

    INSERT INTO staging.Market
    (
        MarketId,
        MarketCode,
        MarketName,
        CountryCode,
        Currency,
        IsActive,
        CreatedAt,
        UpdatedAt
    )
    SELECT
        MarketId,
        MarketCode,
        MarketName,
        CountryCode,
        Currency,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM trading.Market;


    /* ========================================================
       5. Încarcă Instrument
       ======================================================== */

    INSERT INTO staging.Instrument
    (
        InstrumentId,
        MarketId,
        IssuerId,
        Symbol,
        InstrumentName,
        InstrumentType,
        Currency,
        IsActive,
        CreatedAt,
        UpdatedAt
    )
    SELECT
        InstrumentId,
        MarketId,
        IssuerId,
        Symbol,
        InstrumentName,
        InstrumentType,
        Currency,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM trading.Instrument;


    /* ========================================================
       6. Încarcă Ordin
       ======================================================== */

    INSERT INTO staging.[Order]
    (
        OrderId,
        AccountId,
        InstrumentId,
        Side,
        OrderType,
        Quantity,
        LimitPrice,
        StopPrice,
        TimeInForce,
        ExpiresAt,
        OriginalQuantity,
        CancelledQuantity,
        Status,
        CreatedAt,
        UpdatedAt
    )
    SELECT
        OrderId,
        AccountId,
        InstrumentId,
        Side,
        OrderType,
        Quantity,
        LimitPrice,
        StopPrice,
        TimeInForce,
        ExpiresAt,
        OriginalQuantity,
        CancelledQuantity,
        Status,
        CreatedAt,
        UpdatedAt
    FROM trading.[Order];


    /* ========================================================
       7. Încarcă Execuție
       ======================================================== */

    INSERT INTO staging.Execution
    (
        ExecutionId,
        OrderId,
        ExecutedQuantity,
        ExecutionPrice,
        ExecutedAt,
        CreatedAt,
        TradeCurrency,
        ReportingCurrency,
        ExchangeRateToReporting,
        ExchangeRateDate,
        ExchangeRateSource,
        TradeValueReporting,
        CommissionReporting
    )
    SELECT
        ExecutionId,
        OrderId,
        ExecutedQuantity,
        ExecutionPrice,
        ExecutedAt,
        CreatedAt,
        TradeCurrency,
        ReportingCurrency,
        ExchangeRateToReporting,
        ExchangeRateDate,
        ExchangeRateSource,
        TradeValueReporting,
        CommissionReporting
    FROM trading.Execution;


    /* ========================================================
       8. Încarcă CashTransaction
       ======================================================== */

    INSERT INTO staging.CashTransaction
    (
        CashTransactionId,
        CashAccountId,
        TransactionType,
        Amount,
        Currency,
        ReferenceType,
        ReferenceId,
        Description,
        CreatedAt
    )
    SELECT
        CashTransactionId,
        CashAccountId,
        TransactionType,
        Amount,
        Currency,
        ReferenceType,
        ReferenceId,
        Description,
        CreatedAt
    FROM trading.CashTransaction;


    COMMIT TRANSACTION;

    PRINT N'Încărcarea inițială în staging s-a finalizat cu succes.';

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT N'Încărcarea inițială în staging a eșuat.';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO

/* ========================================================
   TEST 1
 ======================================================== */

SELECT 'Customer' AS TableName, COUNT(*) AS TotalRows
FROM staging.Customer

UNION ALL

SELECT 'Account', COUNT(*)
FROM staging.Account

UNION ALL

SELECT 'Market', COUNT(*)
FROM staging.Market

UNION ALL

SELECT 'Instrument', COUNT(*)
FROM staging.Instrument

UNION ALL

SELECT 'Order', COUNT(*)
FROM staging.[Order]

UNION ALL

SELECT 'Execution', COUNT(*)
FROM staging.Execution

UNION ALL

SELECT 'CashTransaction', COUNT(*)
FROM staging.CashTransaction;

/* ========================================================
   TEST 2
 ======================================================== */

SELECT
    'Customer' AS TableName,
    (SELECT COUNT(*) FROM core.Customer) AS SourceRows,
    (SELECT COUNT(*) FROM staging.Customer) AS StagingRows

UNION ALL

SELECT
    'Account',
    (SELECT COUNT(*) FROM core.Account),
    (SELECT COUNT(*) FROM staging.Account)

UNION ALL

SELECT
    'Market',
    (SELECT COUNT(*) FROM trading.Market),
    (SELECT COUNT(*) FROM staging.Market)

UNION ALL

SELECT
    'Instrument',
    (SELECT COUNT(*) FROM trading.Instrument),
    (SELECT COUNT(*) FROM staging.Instrument)

UNION ALL

SELECT
    'Order',
    (SELECT COUNT(*) FROM trading.[Order]),
    (SELECT COUNT(*) FROM staging.[Order])

UNION ALL

SELECT
    'Execution',
    (SELECT COUNT(*) FROM trading.Execution),
    (SELECT COUNT(*) FROM staging.Execution)

UNION ALL

SELECT
    'CashTransaction',
    (SELECT COUNT(*) FROM trading.CashTransaction),
    (SELECT COUNT(*) FROM staging.CashTransaction);
