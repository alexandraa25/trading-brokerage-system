USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Migrează depozitul existent și încarcă raportarea valutară în EUR. */

IF OBJECT_ID('dw.DimCurrency', 'U') IS NULL
BEGIN
    CREATE TABLE dw.DimCurrency
    (
        CurrencyKey         INT IDENTITY(1,1) NOT NULL,
        CurrencyCode        CHAR(3)       NOT NULL,
        CurrencyName        NVARCHAR(100) NOT NULL,
        MinorUnit           TINYINT       NOT NULL,
        IsActive            BIT           NOT NULL,
        IsReportingCurrency BIT           NOT NULL,
        SourceUpdatedAt     DATETIME2(3)  NOT NULL,
        DWCreatedAt         DATETIME2(3)  NOT NULL
            CONSTRAINT DF_DimCurrency_DWCreatedAt DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt         DATETIME2(3)  NOT NULL
            CONSTRAINT DF_DimCurrency_DWUpdatedAt DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_DimCurrency PRIMARY KEY (CurrencyKey),
        CONSTRAINT UQ_DimCurrency_CurrencyCode UNIQUE (CurrencyCode)
    );
END;
GO

MERGE dw.DimCurrency AS target
USING BrokerageDB.core.Currency AS source
    ON source.CurrencyCode = target.CurrencyCode
WHEN MATCHED THEN
    UPDATE SET
        CurrencyName = source.CurrencyName,
        MinorUnit = source.MinorUnit,
        IsActive = source.IsActive,
        IsReportingCurrency = source.IsReportingCurrency,
        SourceUpdatedAt = source.UpdatedAt,
        DWUpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT
    (
        CurrencyCode, CurrencyName, MinorUnit, IsActive,
        IsReportingCurrency, SourceUpdatedAt
    )
    VALUES
    (
        source.CurrencyCode, source.CurrencyName, source.MinorUnit,
        source.IsActive, source.IsReportingCurrency, source.UpdatedAt
    );
GO

IF COL_LENGTH('dw.FactTrade', 'TradeCurrencyKey') IS NULL
    ALTER TABLE dw.FactTrade ADD TradeCurrencyKey INT NULL;
IF COL_LENGTH('dw.FactTrade', 'ReportingCurrencyKey') IS NULL
    ALTER TABLE dw.FactTrade ADD ReportingCurrencyKey INT NULL;
IF COL_LENGTH('dw.FactTrade', 'ExchangeRateDateKey') IS NULL
    ALTER TABLE dw.FactTrade ADD ExchangeRateDateKey INT NULL;
IF COL_LENGTH('dw.FactTrade', 'ExchangeRateToReporting') IS NULL
    ALTER TABLE dw.FactTrade ADD ExchangeRateToReporting DECIMAL(19,10) NULL;
IF COL_LENGTH('dw.FactTrade', 'ExchangeRateSource') IS NULL
    ALTER TABLE dw.FactTrade ADD ExchangeRateSource VARCHAR(50) NULL;
IF COL_LENGTH('dw.FactTrade', 'TradeValueReporting') IS NULL
    ALTER TABLE dw.FactTrade ADD TradeValueReporting DECIMAL(19,4) NULL;
IF COL_LENGTH('dw.FactTrade', 'CommissionReporting') IS NULL
    ALTER TABLE dw.FactTrade ADD CommissionReporting DECIMAL(19,4) NULL;
GO

UPDATE fact
SET
    TradeCurrencyKey = trade_currency.CurrencyKey,
    ReportingCurrencyKey = reporting_currency.CurrencyKey,
    ExchangeRateDateKey = CONVERT
        (INT, CONVERT(CHAR(8), execution_row.ExchangeRateDate, 112)),
    ExchangeRateToReporting = execution_row.ExchangeRateToReporting,
    ExchangeRateSource = execution_row.ExchangeRateSource,
    TradeValueReporting = execution_row.TradeValueReporting,
    CommissionReporting = execution_row.CommissionReporting
FROM dw.FactTrade fact
INNER JOIN BrokerageDB.trading.Execution execution_row
    ON execution_row.ExecutionId = fact.ExecutionId
INNER JOIN dw.DimCurrency trade_currency
    ON trade_currency.CurrencyCode = execution_row.TradeCurrency
INNER JOIN dw.DimCurrency reporting_currency
    ON reporting_currency.CurrencyCode = execution_row.ReportingCurrency;
GO

IF EXISTS
(
    SELECT 1 FROM dw.FactTrade
    WHERE TradeCurrencyKey IS NULL OR ReportingCurrencyKey IS NULL
       OR ExchangeRateDateKey IS NULL OR ExchangeRateToReporting IS NULL
       OR ExchangeRateSource IS NULL
       OR TradeValueReporting IS NULL OR CommissionReporting IS NULL
)
    THROW 54020, N'FactTrade conține rânduri care nu au putut fi convertite în EUR.', 1;
GO

ALTER TABLE dw.FactTrade ALTER COLUMN TradeCurrencyKey INT NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN ReportingCurrencyKey INT NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN ExchangeRateDateKey INT NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN ExchangeRateToReporting DECIMAL(19,10) NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN ExchangeRateSource VARCHAR(50) NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN TradeValueReporting DECIMAL(19,4) NOT NULL;
ALTER TABLE dw.FactTrade ALTER COLUMN CommissionReporting DECIMAL(19,4) NOT NULL;
GO

IF OBJECT_ID('dw.FK_FactTrade_TradeCurrency', 'F') IS NULL
    ALTER TABLE dw.FactTrade ADD CONSTRAINT FK_FactTrade_TradeCurrency
        FOREIGN KEY (TradeCurrencyKey) REFERENCES dw.DimCurrency(CurrencyKey);
IF OBJECT_ID('dw.FK_FactTrade_ReportingCurrency', 'F') IS NULL
    ALTER TABLE dw.FactTrade ADD CONSTRAINT FK_FactTrade_ReportingCurrency
        FOREIGN KEY (ReportingCurrencyKey) REFERENCES dw.DimCurrency(CurrencyKey);
IF OBJECT_ID('dw.FK_FactTrade_ExchangeRateDate', 'F') IS NULL
    ALTER TABLE dw.FactTrade ADD CONSTRAINT FK_FactTrade_ExchangeRateDate
        FOREIGN KEY (ExchangeRateDateKey) REFERENCES dw.DimDate(DateKey);
IF OBJECT_ID('dw.CK_FactTrade_ExchangeRate', 'C') IS NULL
    ALTER TABLE dw.FactTrade ADD CONSTRAINT CK_FactTrade_ExchangeRate
        CHECK (ExchangeRateToReporting > 0);
IF OBJECT_ID('dw.CK_FactTrade_ReportingValues', 'C') IS NULL
    ALTER TABLE dw.FactTrade ADD CONSTRAINT CK_FactTrade_ReportingValues
        CHECK (TradeValueReporting > 0 AND CommissionReporting >= 0);
GO

IF OBJECT_ID('dw.FactExchangeRate', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactExchangeRate
    (
        ExchangeRateKey   BIGINT IDENTITY(1,1) NOT NULL,
        DateKey           INT NOT NULL,
        SourceCurrencyKey INT NOT NULL,
        TargetCurrencyKey INT NOT NULL,
        ExchangeRateId    BIGINT NOT NULL,
        MidRate           DECIMAL(19,10) NOT NULL,
        BuyRate           DECIMAL(19,10) NOT NULL,
        SellRate          DECIMAL(19,10) NOT NULL,
        SourceSystem      VARCHAR(50) NOT NULL,
        DWCreatedAt       DATETIME2(3) NOT NULL
            CONSTRAINT DF_FactExchangeRate_DWCreatedAt DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_FactExchangeRate PRIMARY KEY (ExchangeRateKey),
        CONSTRAINT UQ_FactExchangeRate_ExchangeRateId UNIQUE (ExchangeRateId),
        CONSTRAINT FK_FactExchangeRate_Date FOREIGN KEY (DateKey)
            REFERENCES dw.DimDate(DateKey),
        CONSTRAINT FK_FactExchangeRate_SourceCurrency FOREIGN KEY (SourceCurrencyKey)
            REFERENCES dw.DimCurrency(CurrencyKey),
        CONSTRAINT FK_FactExchangeRate_TargetCurrency FOREIGN KEY (TargetCurrencyKey)
            REFERENCES dw.DimCurrency(CurrencyKey),
        CONSTRAINT CK_FactExchangeRate_Rates CHECK
            (MidRate > 0 AND BuyRate > 0 AND SellRate > 0)
    );
END;
GO

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
    DateKey, SourceCurrencyKey, TargetCurrencyKey, ExchangeRateId,
    MidRate, BuyRate, SellRate, SourceSystem
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
    SELECT 1 FROM dw.FactExchangeRate existing
    WHERE existing.ExchangeRateId = rate_row.ExchangeRateId
);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactTrade')
      AND name = 'IX_FactTrade_ReportingCurrency_Date'
)
BEGIN
    CREATE INDEX IX_FactTrade_ReportingCurrency_Date
        ON dw.FactTrade(ReportingCurrencyKey, DateKey)
        INCLUDE
        (
            TradeCurrencyKey, InstrumentKey,
            TradeValueReporting, CommissionReporting
        );
END;

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactExchangeRate')
      AND name = 'IX_FactExchangeRate_Source_Target_Date'
)
BEGIN
    CREATE INDEX IX_FactExchangeRate_Source_Target_Date
        ON dw.FactExchangeRate(SourceCurrencyKey, TargetCurrencyKey, DateKey)
        INCLUDE (MidRate, BuyRate, SellRate);
END;
GO

PRINT N'Raportarea valutară în EUR a fost încărcată în BrokerageDW.';
GO
