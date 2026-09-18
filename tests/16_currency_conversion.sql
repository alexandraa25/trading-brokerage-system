USE BrokerageDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Teste pentru conversia valutară și instantaneele istorice în EUR. */

IF (SELECT COUNT(*) FROM core.Currency WHERE IsReportingCurrency = 1) <> 1
    THROW 54101, N'TEST EȘUAT: trebuie să existe exact o valută de raportare.', 1;

IF NOT EXISTS
(
    SELECT 1 FROM core.Currency
    WHERE CurrencyCode = 'EUR' AND IsReportingCurrency = 1
)
    THROW 54102, N'TEST EȘUAT: EUR nu este valuta de raportare.', 1;

IF core.fn_GetExchangeRate('EUR', 'EUR', CAST(SYSUTCDATETIME() AS DATE)) <> 1
    THROW 54103, N'TEST EȘUAT: cursul EUR/EUR trebuie să fie 1.', 1;

IF core.fn_GetExchangeRate('XXX', 'EUR', CAST(SYSUTCDATETIME() AS DATE)) IS NOT NULL
    THROW 54108, N'TEST EȘUAT: o valută necunoscută nu trebuie convertită.', 1;

DECLARE
    @RateDate DATE = '20260917',
    @UsdToEur DECIMAL(19,10),
    @EurToUsd DECIMAL(19,10),
    @UsdToRon DECIMAL(19,10);

SET @UsdToEur = core.fn_GetExchangeRate('USD', 'EUR', @RateDate);
SET @EurToUsd = core.fn_GetExchangeRate('EUR', 'USD', @RateDate);
SET @UsdToRon = core.fn_GetExchangeRate('USD', 'RON', @RateDate);

IF @UsdToEur IS NULL OR @EurToUsd IS NULL OR @UsdToRon IS NULL
    THROW 54104, N'TEST EȘUAT: lipsesc conversii directe, inverse sau încrucișate.', 1;

IF ABS((@UsdToEur * @EurToUsd) - 1) > 0.000001
    THROW 54105, N'TEST EȘUAT: rata inversă nu este corectă.', 1;

IF EXISTS
(
    SELECT 1
    FROM trading.Execution
    WHERE ReportingCurrency <> 'EUR'
       OR ExchangeRateToReporting <= 0
       OR ExchangeRateDate > CAST(ExecutedAt AS DATE)
       OR DATEDIFF(DAY, ExchangeRateDate, CAST(ExecutedAt AS DATE)) > 7
       OR ExchangeRateSource NOT IN ('ECB_REFERENCE', 'IDENTITY')
       OR ABS
          (
              TradeValueReporting
              - ROUND(ExecutedQuantity * ExecutionPrice * ExchangeRateToReporting, 4)
          ) > 0.0001
       OR CommissionReporting < 0
)
    THROW 54106, N'TEST EȘUAT: există execuții cu instantanee valutare invalide.', 1;

/* O modificare a cursului sursă nu trebuie să rescrie execuțiile istorice. */
DECLARE
    @ExecutionId BIGINT,
    @StoredValue DECIMAL(19,4),
    @SourceCurrency CHAR(3),
    @StoredRateDate DATE;

SELECT TOP (1)
    @ExecutionId = ExecutionId,
    @StoredValue = TradeValueReporting,
    @SourceCurrency = TradeCurrency,
    @StoredRateDate = ExchangeRateDate
FROM trading.Execution
WHERE TradeCurrency <> 'EUR'
ORDER BY ExecutionId;

IF @ExecutionId IS NOT NULL
BEGIN
    BEGIN TRANSACTION;

    UPDATE core.ExchangeRate
    SET MidRate = MidRate * 1.01,
        BuyRate = BuyRate * 1.01,
        SellRate = SellRate * 1.01
    WHERE SourceCurrency = @SourceCurrency
      AND TargetCurrency = 'EUR'
      AND RateDate = @StoredRateDate;

    IF (SELECT TradeValueReporting FROM trading.Execution WHERE ExecutionId = @ExecutionId)
       <> @StoredValue
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 54107, N'TEST EȘUAT: valoarea istorică a execuției s-a modificat.', 1;
    END;

    ROLLBACK TRANSACTION;
END;

PRINT N'============================================';
PRINT N'TESTUL #16 A TRECUT';
PRINT N'Conversia valutară în EUR este validă.';
PRINT N'============================================';
GO
