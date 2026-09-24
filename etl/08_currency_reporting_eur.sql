USE BrokerageDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Extinde staging.Execution cu instantaneul conversiei valutare în EUR. */

IF COL_LENGTH('staging.Execution', 'TradeCurrency') IS NULL
    ALTER TABLE staging.Execution ADD TradeCurrency CHAR(3) NULL;
IF COL_LENGTH('staging.Execution', 'ReportingCurrency') IS NULL
    ALTER TABLE staging.Execution ADD ReportingCurrency CHAR(3) NULL;
IF COL_LENGTH('staging.Execution', 'ExchangeRateToReporting') IS NULL
    ALTER TABLE staging.Execution ADD ExchangeRateToReporting DECIMAL(19,10) NULL;
IF COL_LENGTH('staging.Execution', 'ExchangeRateDate') IS NULL
    ALTER TABLE staging.Execution ADD ExchangeRateDate DATE NULL;
IF COL_LENGTH('staging.Execution', 'ExchangeRateSource') IS NULL
    ALTER TABLE staging.Execution ADD ExchangeRateSource VARCHAR(50) NULL;
IF COL_LENGTH('staging.Execution', 'TradeValueReporting') IS NULL
    ALTER TABLE staging.Execution ADD TradeValueReporting DECIMAL(19,4) NULL;
IF COL_LENGTH('staging.Execution', 'CommissionReporting') IS NULL
    ALTER TABLE staging.Execution ADD CommissionReporting DECIMAL(19,4) NULL;
GO

UPDATE staging_row
SET
    TradeCurrency = source_row.TradeCurrency,
    ReportingCurrency = source_row.ReportingCurrency,
    ExchangeRateToReporting = source_row.ExchangeRateToReporting,
    ExchangeRateDate = source_row.ExchangeRateDate,
    ExchangeRateSource = source_row.ExchangeRateSource,
    TradeValueReporting = source_row.TradeValueReporting,
    CommissionReporting = source_row.CommissionReporting
FROM staging.Execution staging_row
INNER JOIN trading.Execution source_row
    ON source_row.ExecutionId = staging_row.ExecutionId;
GO

IF EXISTS
(
    SELECT 1 FROM staging.Execution
    WHERE TradeCurrency IS NULL OR ReportingCurrency IS NULL
       OR ExchangeRateToReporting IS NULL OR ExchangeRateDate IS NULL
       OR ExchangeRateSource IS NULL
       OR TradeValueReporting IS NULL OR CommissionReporting IS NULL
)
    THROW 54010, N'Staging conține execuții fără conversie valutară.', 1;
GO

ALTER TABLE staging.Execution ALTER COLUMN TradeCurrency CHAR(3) NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN ReportingCurrency CHAR(3) NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN ExchangeRateToReporting DECIMAL(19,10) NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN ExchangeRateDate DATE NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN ExchangeRateSource VARCHAR(50) NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN TradeValueReporting DECIMAL(19,4) NOT NULL;
ALTER TABLE staging.Execution ALTER COLUMN CommissionReporting DECIMAL(19,4) NOT NULL;
GO

PRINT N'Staging-ul valutar în EUR a fost configurat.';
GO
