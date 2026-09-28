USE BrokerageDB;
GO

/*
Reîncarcă integral staging-ul din OLTP.
Scriptul este compatibil atât cu versiunea inițială a schemei, cât și cu
versiunea în care Account, Market și Instrument au coloana UpdatedAt.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE staging.CashTransaction;
    TRUNCATE TABLE staging.Execution;
    TRUNCATE TABLE staging.[Order];
    TRUNCATE TABLE staging.Instrument;
    TRUNCATE TABLE staging.Market;
    TRUNCATE TABLE staging.Account;
    TRUNCATE TABLE staging.Customer;

    INSERT INTO staging.Customer
    (
        CustomerId, CustomerTypeId, FirstName, LastName, Email,
        Phone, DateOfBirth, Status, CreatedAt, UpdatedAt
    )
    SELECT
        CustomerId, CustomerTypeId, FirstName, LastName, Email,
        Phone, DateOfBirth, Status, CreatedAt, UpdatedAt
    FROM core.Customer;

    IF COL_LENGTH('core.Account', 'UpdatedAt') IS NOT NULL
       AND COL_LENGTH('staging.Account', 'UpdatedAt') IS NOT NULL
    BEGIN
        EXEC
        (
            'INSERT INTO staging.Account
             (AccountId, CustomerId, AccountNumber, Currency, Status,
              CreatedAt, UpdatedAt, ClosedAt)
             SELECT AccountId, CustomerId, AccountNumber, Currency, Status,
                    CreatedAt, UpdatedAt, ClosedAt
             FROM core.Account;'
        );
    END
    ELSE
    BEGIN
        INSERT INTO staging.Account
            (AccountId, CustomerId, AccountNumber, Currency, Status, CreatedAt, ClosedAt)
        SELECT AccountId, CustomerId, AccountNumber, Currency, Status, CreatedAt, ClosedAt
        FROM core.Account;
    END;

    IF COL_LENGTH('trading.Market', 'UpdatedAt') IS NOT NULL
       AND COL_LENGTH('staging.Market', 'UpdatedAt') IS NOT NULL
    BEGIN
        EXEC
        (
            'INSERT INTO staging.Market
             (MarketId, MarketCode, MarketName, CountryCode, Currency,
              IsActive, CreatedAt, UpdatedAt)
             SELECT MarketId, MarketCode, MarketName, CountryCode, Currency,
                    IsActive, CreatedAt, UpdatedAt
             FROM trading.Market;'
        );
    END
    ELSE
    BEGIN
        INSERT INTO staging.Market
            (MarketId, MarketCode, MarketName, CountryCode, Currency, IsActive, CreatedAt)
        SELECT MarketId, MarketCode, MarketName, CountryCode, Currency, IsActive, CreatedAt
        FROM trading.Market;
    END;

    IF COL_LENGTH('trading.Instrument', 'UpdatedAt') IS NOT NULL
       AND COL_LENGTH('staging.Instrument', 'UpdatedAt') IS NOT NULL
    BEGIN
        EXEC
        (
            'INSERT INTO staging.Instrument
             (InstrumentId, MarketId, IssuerId, Symbol, InstrumentName,
              InstrumentType, Currency, IsActive, CreatedAt, UpdatedAt)
             SELECT InstrumentId, MarketId, IssuerId, Symbol, InstrumentName,
                    InstrumentType, Currency, IsActive, CreatedAt, UpdatedAt
             FROM trading.Instrument;'
        );
    END
    ELSE
    BEGIN
        INSERT INTO staging.Instrument
        (
            InstrumentId, MarketId, IssuerId, Symbol, InstrumentName,
            InstrumentType, Currency, IsActive, CreatedAt
        )
        SELECT
            InstrumentId, MarketId, IssuerId, Symbol, InstrumentName,
            InstrumentType, Currency, IsActive, CreatedAt
        FROM trading.Instrument;
    END;

    INSERT INTO staging.[Order]
    (
        OrderId, AccountId, InstrumentId, Side, OrderType,
        Quantity, LimitPrice, StopPrice, TimeInForce, ExpiresAt, OriginalQuantity, CancelledQuantity, Status, CreatedAt, UpdatedAt
    )
    SELECT
        OrderId, AccountId, InstrumentId, Side, OrderType,
        Quantity, LimitPrice, StopPrice, TimeInForce, ExpiresAt, OriginalQuantity, CancelledQuantity, Status, CreatedAt, UpdatedAt
    FROM trading.[Order];

    INSERT INTO staging.Execution
    (
        ExecutionId, OrderId, ExecutedQuantity,
        ExecutionPrice, ExecutedAt, CreatedAt,
        TradeCurrency, ReportingCurrency, ExchangeRateToReporting,
        ExchangeRateDate, ExchangeRateSource,
        TradeValueReporting, CommissionReporting
    )
    SELECT
        ExecutionId, OrderId, ExecutedQuantity,
        ExecutionPrice, ExecutedAt, CreatedAt,
        TradeCurrency, ReportingCurrency, ExchangeRateToReporting,
        ExchangeRateDate, ExchangeRateSource,
        TradeValueReporting, CommissionReporting
    FROM trading.Execution;

    INSERT INTO staging.CashTransaction
    (
        CashTransactionId, CashAccountId, TransactionType, Amount,
        Currency, ReferenceType, ReferenceId, Description, CreatedAt
    )
    SELECT
        CashTransactionId, CashAccountId, TransactionType, Amount,
        Currency, ReferenceType, ReferenceId, Description, CreatedAt
    FROM trading.CashTransaction;

    IF OBJECT_ID('staging.ETLWatermark') IS NOT NULL
    BEGIN
        UPDATE staging.ETLWatermark
        SET LastSuccessfulLoad = SYSUTCDATETIME(),
            UpdatedAt = SYSUTCDATETIME()
        WHERE EntityName IN
            ('Customer', 'Account', 'Market', 'Instrument',
             'Order', 'Execution', 'CashTransaction');
    END;

    COMMIT TRANSACTION;
    PRINT N'Reîncărcarea completă a staging-ului s-a finalizat cu succes.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT 'Customer' AS EntityName, COUNT(*) AS TotalRows FROM staging.Customer
UNION ALL SELECT 'Account', COUNT(*) FROM staging.Account
UNION ALL SELECT 'Market', COUNT(*) FROM staging.Market
UNION ALL SELECT 'Instrument', COUNT(*) FROM staging.Instrument
UNION ALL SELECT 'Order', COUNT(*) FROM staging.[Order]
UNION ALL SELECT 'Execution', COUNT(*) FROM staging.Execution
UNION ALL SELECT 'CashTransaction', COUNT(*) FROM staging.CashTransaction;
GO
