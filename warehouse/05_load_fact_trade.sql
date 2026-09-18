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

        OrderId,
        ExecutionId,

        Side,
        OrderType,

        ExecutedQuantity,
        ExecutionPrice,
        CommissionAmount,

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
    OrderId,
    ExecutionId,
    Side,
    OrderType,
    ExecutedQuantity,
    ExecutionPrice,
    TradeValue,
    CommissionAmount,
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
    SUM(TradeValue) AS TotalTradingVolume
FROM dw.FactTrade;


SELECT
    COUNT(*) AS TradeCount
FROM dw.FactTrade;

SELECT
    SUM(CommissionAmount) AS TotalCommission
FROM dw.FactTrade;

SELECT
    Side,
    COUNT(*) AS TradeCount,
    SUM(ExecutedQuantity) AS TotalQuantity,
    SUM(TradeValue) AS TradingVolume,
    SUM(CommissionAmount) AS CommissionRevenue
FROM dw.FactTrade
GROUP BY Side
ORDER BY Side;
