USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   DW #5 - Încarcă FactTrade

   Granularitate:
       Un rând = o execuție

   Surse:
       BrokerageDB.staging.Execution
       BrokerageDB.staging.Order
       BrokerageDB.trading.Commission

   Dimensiuni:
       dw.DimDate
       dw.DimCustomer
       dw.DimAccount
       dw.DimInstrument

   Destinație:
       dw.FactTrade

   Strategie:
       Incrementală / idempotentă
       ExecutionId previne faptele duplicat
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @RowsInserted BIGINT = 0;

BEGIN TRY

    BEGIN TRANSACTION;


    /* ========================================================
       Inserează execuțiile care nu există deja în FactTrade
       ======================================================== */

    INSERT INTO dw.FactTrade
    (
        DateKey,
        CustomerKey,
        AccountKey,
        InstrumentKey,
        TradeCurrencyKey,
        ReportingCurrencyKey,
        ExchangeRateDateKey,

        OrderId,
        ExecutionId,

        Side,
        OrderType,

        ExecutedQuantity,
        ExecutionPrice,
        CommissionAmount,
        ExchangeRateToReporting,
        ExchangeRateSource,
        TradeValueReporting,
        CommissionReporting,

        ExecutedAt
    )
    SELECT
        /* YYYYMMDD */
        CONVERT
        (
            INT,
            CONVERT
            (
                CHAR(8),
                CAST(execution.ExecutedAt AS DATE),
                112
            )
        ) AS DateKey,

        customer.CustomerKey,

        account.AccountKey,

        instrument.InstrumentKey,

        trade_currency.CurrencyKey,

        reporting_currency.CurrencyKey,

        CONVERT(INT, CONVERT(CHAR(8), execution.ExchangeRateDate, 112)),

        orders.OrderId,

        execution.ExecutionId,

        orders.Side,

        orders.OrderType,

        execution.ExecutedQuantity,

        execution.ExecutionPrice,

        ISNULL
        (
            commission.TotalCommission,
            0
        ) AS CommissionAmount,

        execution.ExchangeRateToReporting,

        execution.ExchangeRateSource,

        execution.TradeValueReporting,

        execution.CommissionReporting,

        execution.ExecutedAt

    FROM BrokerageDB.staging.Execution AS execution

    INNER JOIN BrokerageDB.staging.[Order] AS orders
        ON orders.OrderId = execution.OrderId

    INNER JOIN dw.DimAccount AS account
        ON account.AccountId = orders.AccountId

    INNER JOIN dw.DimCustomer AS customer
        ON customer.CustomerId = account.CustomerId

    INNER JOIN dw.DimInstrument AS instrument
        ON instrument.InstrumentId =
           orders.InstrumentId

    INNER JOIN dw.DimCurrency AS trade_currency
        ON trade_currency.CurrencyCode = execution.TradeCurrency

    INNER JOIN dw.DimCurrency AS reporting_currency
        ON reporting_currency.CurrencyCode = execution.ReportingCurrency

    INNER JOIN dw.DimDate AS calendar
        ON calendar.DateKey =
           CONVERT
           (
               INT,
               CONVERT
               (
                   CHAR(8),
                   CAST(execution.ExecutedAt AS DATE),
                   112
               )
           )

    OUTER APPLY
    (
        SELECT
            SUM(c.Amount) AS TotalCommission
        FROM BrokerageDB.trading.Commission AS c
        WHERE c.ExecutionId =
              execution.ExecutionId
    ) AS commission

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.FactTrade AS fact
        WHERE fact.ExecutionId =
              execution.ExecutionId
    );

    SET @RowsInserted = @@ROWCOUNT;


    DELETE fact_rate
    FROM dw.FactExchangeRate fact_rate
    WHERE NOT EXISTS
    (
        SELECT 1 FROM BrokerageDB.core.ExchangeRate source_rate
        WHERE source_rate.ExchangeRateId = fact_rate.ExchangeRateId
    );

    UPDATE fact_rate
    SET
        DateKey = CONVERT(INT, CONVERT(CHAR(8), source_rate.RateDate, 112)),
        SourceCurrencyKey = source_currency.CurrencyKey,
        TargetCurrencyKey = target_currency.CurrencyKey,
        MidRate = source_rate.MidRate,
        BuyRate = source_rate.BuyRate,
        SellRate = source_rate.SellRate,
        SourceSystem = source_rate.SourceSystem
    FROM dw.FactExchangeRate fact_rate
    INNER JOIN BrokerageDB.core.ExchangeRate source_rate
        ON source_rate.ExchangeRateId = fact_rate.ExchangeRateId
    INNER JOIN dw.DimCurrency source_currency
        ON source_currency.CurrencyCode = source_rate.SourceCurrency
    INNER JOIN dw.DimCurrency target_currency
        ON target_currency.CurrencyCode = source_rate.TargetCurrency;

    INSERT INTO dw.FactExchangeRate
    (
        DateKey,
        SourceCurrencyKey,
        TargetCurrencyKey,
        ExchangeRateId,
        MidRate,
        BuyRate,
        SellRate,
        SourceSystem
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), rate_row.RateDate, 112)),
        source_currency.CurrencyKey,
        target_currency.CurrencyKey,
        rate_row.ExchangeRateId,
        rate_row.MidRate,
        rate_row.BuyRate,
        rate_row.SellRate,
        rate_row.SourceSystem
    FROM BrokerageDB.core.ExchangeRate rate_row
    INNER JOIN dw.DimCurrency source_currency
        ON source_currency.CurrencyCode = rate_row.SourceCurrency
    INNER JOIN dw.DimCurrency target_currency
        ON target_currency.CurrencyCode = rate_row.TargetCurrency
    INNER JOIN dw.DimDate rate_date
        ON rate_date.DateKey = CONVERT(INT, CONVERT(CHAR(8), rate_row.RateDate, 112))
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.FactExchangeRate existing
        WHERE existing.ExchangeRateId = rate_row.ExchangeRateId
    );


    COMMIT TRANSACTION;


    PRINT N'Încărcarea FactTrade s-a finalizat cu succes.';
    PRINT CONCAT
    (
        'Rows inserted: ',
        @RowsInserted
    );

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT N'Încărcarea FactTrade a eșuat.';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO



SELECT
    TradeKey,
    DateKey,
    CustomerKey,
    AccountKey,
    InstrumentKey,
    TradeCurrencyKey,
    ReportingCurrencyKey,
    ExchangeRateDateKey,
    OrderId,
    ExecutionId,
    Side,
    OrderType,
    ExecutedQuantity,
    ExecutionPrice,
    TradeValue,
    CommissionAmount,
    ExchangeRateToReporting,
    ExchangeRateSource,
    TradeValueReporting,
    CommissionReporting,
    ExecutedAt
FROM dw.FactTrade
ORDER BY TradeKey;


SELECT
    (SELECT COUNT(*)
     FROM BrokerageDB.staging.Execution)
        AS StagingExecutions,

    (SELECT COUNT(*)
     FROM dw.FactTrade)
        AS FactTrades;



        SELECT TOP (20)
    f.TradeKey,

    f.ExecutionId,
    f.OrderId,

    c.CustomerKey,
    c.CustomerId,
    c.FullName,

    a.AccountKey,
    a.AccountId,
    a.AccountNumber,

    i.InstrumentKey,
    i.InstrumentId,
    i.Symbol,

    d.FullDate,

    f.Side,
    f.ExecutedQuantity,
    f.ExecutionPrice,
    f.TradeValue,
    f.CommissionAmount
    ,f.ExchangeRateToReporting
    ,f.ExchangeRateSource
    ,f.TradeValueReporting
    ,f.CommissionReporting

FROM dw.FactTrade AS f

INNER JOIN dw.DimCustomer AS c
    ON c.CustomerKey = f.CustomerKey

INNER JOIN dw.DimAccount AS a
    ON a.AccountKey = f.AccountKey

INNER JOIN dw.DimInstrument AS i
    ON i.InstrumentKey = f.InstrumentKey

INNER JOIN dw.DimDate AS d
    ON d.DateKey = f.DateKey

ORDER BY f.ExecutedAt DESC;


SELECT
    currency.CurrencyCode,
    SUM(fact.TradeValue) AS TotalTradingVolumeOriginal,
    SUM(fact.CommissionAmount) AS TotalCommissionOriginal
FROM dw.FactTrade fact
INNER JOIN dw.DimCurrency currency
    ON currency.CurrencyKey = fact.TradeCurrencyKey
GROUP BY currency.CurrencyCode
ORDER BY currency.CurrencyCode;

SELECT
    SUM(TradeValueReporting) AS TotalTradingVolumeEUR,
    SUM(CommissionReporting) AS TotalCommissionEUR
FROM dw.FactTrade;


SELECT
    COUNT(*) AS TradeCount
FROM dw.FactTrade;

SELECT
    Side,
    COUNT(*) AS TradeCount,
    SUM(ExecutedQuantity) AS TotalQuantity,
    SUM(TradeValueReporting) AS TradingVolumeEUR,
    SUM(CommissionReporting) AS CommissionRevenueEUR
FROM dw.FactTrade
GROUP BY Side
ORDER BY Side;
