USE BrokerageDW;
GO

SET NOCOUNT ON;
GO

/* Validarea raportării valutare din depozitul de date. */

IF NOT EXISTS
(
    SELECT 1 FROM dw.DimCurrency
    WHERE CurrencyCode = 'EUR' AND IsReportingCurrency = 1
)
    THROW 54201, N'TEST EȘUAT: DimCurrency nu identifică EUR drept valută principală.', 1;

IF (SELECT COUNT(*) FROM BrokerageDB.core.ExchangeRate)
   <> (SELECT COUNT(*) FROM dw.FactExchangeRate)
    THROW 54202, N'TEST EȘUAT: FactExchangeRate nu corespunde sursei.', 1;

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade fact
    INNER JOIN dw.DimCurrency reporting_currency
        ON reporting_currency.CurrencyKey = fact.ReportingCurrencyKey
    WHERE reporting_currency.CurrencyCode <> 'EUR'
       OR fact.ExchangeRateSource NOT IN ('ECB_REFERENCE', 'IDENTITY')
       OR fact.ExchangeRateToReporting <= 0
       OR fact.TradeValueReporting <= 0
       OR fact.CommissionReporting < 0
       OR ABS
          (
              fact.TradeValueReporting
              - ROUND(fact.TradeValue * fact.ExchangeRateToReporting, 4)
          ) > 0.0001
)
    THROW 54203, N'TEST EȘUAT: FactTrade conține conversii EUR invalide.', 1;

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade fact
    LEFT JOIN dw.DimDate rate_date
        ON rate_date.DateKey = fact.ExchangeRateDateKey
    LEFT JOIN dw.DimCurrency trade_currency
        ON trade_currency.CurrencyKey = fact.TradeCurrencyKey
    LEFT JOIN dw.DimCurrency reporting_currency
        ON reporting_currency.CurrencyKey = fact.ReportingCurrencyKey
    WHERE rate_date.DateKey IS NULL
       OR trade_currency.CurrencyKey IS NULL
       OR reporting_currency.CurrencyKey IS NULL
)
    THROW 54204, N'TEST EȘUAT: există chei valutare orfane în FactTrade.', 1;

SELECT
    trade_currency.CurrencyCode AS OriginalCurrency,
    COUNT(*) AS TradeCount,
    SUM(fact.TradeValueReporting) AS TradingVolumeEUR,
    SUM(fact.CommissionReporting) AS CommissionEUR
FROM dw.FactTrade fact
INNER JOIN dw.DimCurrency trade_currency
    ON trade_currency.CurrencyKey = fact.TradeCurrencyKey
GROUP BY trade_currency.CurrencyCode
ORDER BY trade_currency.CurrencyCode;

PRINT N'============================================';
PRINT N'TESTUL #17 A TRECUT';
PRINT N'Raportarea valutară din DW este validă.';
PRINT N'============================================';
GO
