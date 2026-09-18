USE BrokerageDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
Adaugă suportul valutar al aplicației.
Convenția cursului este: 1 unitate din SourceCurrency = MidRate unități
din TargetCurrency. EUR este valuta principală de raportare.
Scriptul este idempotent și poate fi rulat atât pe o bază nouă, cât și pe
o bază care conține deja tranzacții.
*/

IF OBJECT_ID('core.Currency', 'U') IS NULL
BEGIN
    CREATE TABLE core.Currency
    (
        CurrencyCode        CHAR(3)       NOT NULL,
        CurrencyName        NVARCHAR(100) NOT NULL,
        MinorUnit           TINYINT       NOT NULL,
        IsActive            BIT           NOT NULL
            CONSTRAINT DF_Currency_IsActive DEFAULT (1),
        IsReportingCurrency BIT           NOT NULL
            CONSTRAINT DF_Currency_IsReportingCurrency DEFAULT (0),
        CreatedAt           DATETIME2(3)  NOT NULL
            CONSTRAINT DF_Currency_CreatedAt DEFAULT (SYSUTCDATETIME()),
        UpdatedAt           DATETIME2(3)  NOT NULL
            CONSTRAINT DF_Currency_UpdatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Currency PRIMARY KEY (CurrencyCode),
        CONSTRAINT CK_Currency_Code CHECK
            (CurrencyCode = UPPER(CurrencyCode) AND CurrencyCode NOT LIKE '%[^A-Z]%'),
        CONSTRAINT CK_Currency_MinorUnit CHECK (MinorUnit BETWEEN 0 AND 8)
    );
END;
GO

MERGE core.Currency AS target
USING
(
    VALUES
        ('EUR', N'Euro',                 2, 1),
        ('USD', N'Dolar american',       2, 0),
        ('GBP', N'Liră sterlină',        2, 0),
        ('RON', N'Leu românesc',         2, 0),
        ('CAD', N'Dolar canadian',       2, 0),
        ('JPY', N'Yen japonez',          0, 0)
) AS source (CurrencyCode, CurrencyName, MinorUnit, IsReportingCurrency)
ON target.CurrencyCode = source.CurrencyCode
WHEN MATCHED THEN
    UPDATE SET
        CurrencyName = source.CurrencyName,
        MinorUnit = source.MinorUnit,
        IsActive = 1,
        IsReportingCurrency = source.IsReportingCurrency,
        UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (CurrencyCode, CurrencyName, MinorUnit, IsActive, IsReportingCurrency)
    VALUES (source.CurrencyCode, source.CurrencyName, source.MinorUnit, 1,
            source.IsReportingCurrency);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('core.Currency')
      AND name = 'UX_Currency_ReportingCurrency'
)
BEGIN
    CREATE UNIQUE INDEX UX_Currency_ReportingCurrency
        ON core.Currency(IsReportingCurrency)
        WHERE IsReportingCurrency = 1;
END;
GO

/* Toate coloanele valutare operaționale trebuie să folosească valute cunoscute. */
IF OBJECT_ID('core.FK_Account_Currency', 'F') IS NULL
    ALTER TABLE core.Account ADD CONSTRAINT FK_Account_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('core.FK_CashAccount_Currency', 'F') IS NULL
    ALTER TABLE core.CashAccount ADD CONSTRAINT FK_CashAccount_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.FK_Market_Currency', 'F') IS NULL
    ALTER TABLE trading.Market ADD CONSTRAINT FK_Market_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.FK_Instrument_Currency', 'F') IS NULL
    ALTER TABLE trading.Instrument ADD CONSTRAINT FK_Instrument_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.FK_Commission_Currency', 'F') IS NULL
    ALTER TABLE trading.Commission ADD CONSTRAINT FK_Commission_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.FK_CashTransaction_Currency', 'F') IS NULL
    ALTER TABLE trading.CashTransaction ADD CONSTRAINT FK_CashTransaction_Currency
        FOREIGN KEY (Currency) REFERENCES core.Currency(CurrencyCode);
GO

IF OBJECT_ID('core.ExchangeRate', 'U') IS NULL
BEGIN
    CREATE TABLE core.ExchangeRate
    (
        ExchangeRateId BIGINT IDENTITY(1,1) NOT NULL,
        SourceCurrency CHAR(3)       NOT NULL,
        TargetCurrency CHAR(3)       NOT NULL,
        RateDate       DATE          NOT NULL,
        MidRate        DECIMAL(19,10) NOT NULL,
        BuyRate        DECIMAL(19,10) NOT NULL,
        SellRate       DECIMAL(19,10) NOT NULL,
        SourceSystem   VARCHAR(50)   NOT NULL,
        CreatedAt      DATETIME2(3)  NOT NULL
            CONSTRAINT DF_ExchangeRate_CreatedAt DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_ExchangeRate PRIMARY KEY (ExchangeRateId),
        CONSTRAINT UQ_ExchangeRate UNIQUE
            (SourceCurrency, TargetCurrency, RateDate),
        CONSTRAINT FK_ExchangeRate_SourceCurrency FOREIGN KEY (SourceCurrency)
            REFERENCES core.Currency(CurrencyCode),
        CONSTRAINT FK_ExchangeRate_TargetCurrency FOREIGN KEY (TargetCurrency)
            REFERENCES core.Currency(CurrencyCode),
        CONSTRAINT CK_ExchangeRate_DifferentCurrencies CHECK
            (SourceCurrency <> TargetCurrency),
        CONSTRAINT CK_ExchangeRate_PositiveRates CHECK
            (MidRate > 0 AND BuyRate > 0 AND SellRate > 0),
        CONSTRAINT CK_ExchangeRate_Spread CHECK
            (BuyRate >= MidRate AND SellRate <= MidRate)
    );

    CREATE INDEX IX_ExchangeRate_Lookup
        ON core.ExchangeRate(SourceCurrency, TargetCurrency, RateDate DESC)
        INCLUDE (MidRate, BuyRate, SellRate, SourceSystem);
END;
GO

/* Cursuri demonstrative zilnice, reproductibile, pentru întregul calendar DW. */
;WITH calendar AS
(
    SELECT CAST('20200101' AS DATE) AS RateDate
    UNION ALL
    SELECT DATEADD(DAY, 1, RateDate)
    FROM calendar
    WHERE RateDate < '20351231'
), base_rate AS
(
    SELECT *
    FROM
    (
        VALUES
            (CAST('USD' AS CHAR(3)), CAST(0.9200000000 AS DECIMAL(19,10))),
            (CAST('GBP' AS CHAR(3)), CAST(1.1700000000 AS DECIMAL(19,10))),
            (CAST('RON' AS CHAR(3)), CAST(0.2010000000 AS DECIMAL(19,10))),
            (CAST('CAD' AS CHAR(3)), CAST(0.6800000000 AS DECIMAL(19,10))),
            (CAST('JPY' AS CHAR(3)), CAST(0.0062000000 AS DECIMAL(19,10)))
    ) value_list (SourceCurrency, BaseMidRate)
), calculated AS
(
    SELECT
        base_rate.SourceCurrency,
        CAST('EUR' AS CHAR(3)) AS TargetCurrency,
        calendar.RateDate,
        CAST
        (
            base_rate.BaseMidRate
            * (1 + ((DATEDIFF(DAY, '20200101', calendar.RateDate) % 31) - 15) / 10000.0)
            AS DECIMAL(19,10)
        ) AS MidRate
    FROM calendar
    CROSS JOIN base_rate
)
INSERT INTO core.ExchangeRate
(
    SourceCurrency, TargetCurrency, RateDate,
    MidRate, BuyRate, SellRate, SourceSystem
)
SELECT
    calculated.SourceCurrency,
    calculated.TargetCurrency,
    calculated.RateDate,
    calculated.MidRate,
    CAST(calculated.MidRate * 1.002 AS DECIMAL(19,10)),
    CAST(calculated.MidRate * 0.998 AS DECIMAL(19,10)),
    'DEMO_EUR_DAILY'
FROM calculated
WHERE NOT EXISTS
(
    SELECT 1
    FROM core.ExchangeRate existing
    WHERE existing.SourceCurrency = calculated.SourceCurrency
      AND existing.TargetCurrency = calculated.TargetCurrency
      AND existing.RateDate = calculated.RateDate
)
OPTION (MAXRECURSION 0);
GO

CREATE OR ALTER FUNCTION core.fn_GetExchangeRate
(
    @SourceCurrency CHAR(3),
    @TargetCurrency CHAR(3),
    @RateDate DATE
)
RETURNS DECIMAL(19,10)
AS
BEGIN
    DECLARE
        @Rate DECIMAL(19,10),
        @SourceToEur DECIMAL(19,10),
        @TargetToEur DECIMAL(19,10);

    SET @SourceCurrency = UPPER(@SourceCurrency);
    SET @TargetCurrency = UPPER(@TargetCurrency);

    IF NOT EXISTS
       (
           SELECT 1 FROM core.Currency
           WHERE CurrencyCode = @SourceCurrency AND IsActive = 1
       )
       OR NOT EXISTS
       (
           SELECT 1 FROM core.Currency
           WHERE CurrencyCode = @TargetCurrency AND IsActive = 1
       )
        RETURN NULL;

    IF @SourceCurrency = @TargetCurrency
        RETURN CAST(1 AS DECIMAL(19,10));

    SELECT TOP (1) @Rate = MidRate
    FROM core.ExchangeRate
    WHERE SourceCurrency = @SourceCurrency
      AND TargetCurrency = @TargetCurrency
      AND RateDate <= @RateDate
    ORDER BY RateDate DESC;

    IF @Rate IS NOT NULL
        RETURN @Rate;

    SELECT TOP (1) @Rate = CAST(1 / MidRate AS DECIMAL(19,10))
    FROM core.ExchangeRate
    WHERE SourceCurrency = @TargetCurrency
      AND TargetCurrency = @SourceCurrency
      AND RateDate <= @RateDate
    ORDER BY RateDate DESC;

    IF @Rate IS NOT NULL
        RETURN @Rate;

    SELECT TOP (1) @SourceToEur = MidRate
    FROM core.ExchangeRate
    WHERE SourceCurrency = @SourceCurrency
      AND TargetCurrency = 'EUR'
      AND RateDate <= @RateDate
    ORDER BY RateDate DESC;

    SELECT TOP (1) @TargetToEur = MidRate
    FROM core.ExchangeRate
    WHERE SourceCurrency = @TargetCurrency
      AND TargetCurrency = 'EUR'
      AND RateDate <= @RateDate
    ORDER BY RateDate DESC;

    IF @SourceToEur IS NOT NULL AND @TargetToEur IS NOT NULL
        RETURN CAST(@SourceToEur / @TargetToEur AS DECIMAL(19,10));

    RETURN NULL;
END;
GO

IF COL_LENGTH('trading.Execution', 'TradeCurrency') IS NULL
    ALTER TABLE trading.Execution ADD TradeCurrency CHAR(3) NULL;
IF COL_LENGTH('trading.Execution', 'ReportingCurrency') IS NULL
    ALTER TABLE trading.Execution ADD ReportingCurrency CHAR(3) NULL;
IF COL_LENGTH('trading.Execution', 'ExchangeRateToReporting') IS NULL
    ALTER TABLE trading.Execution ADD ExchangeRateToReporting DECIMAL(19,10) NULL;
IF COL_LENGTH('trading.Execution', 'ExchangeRateDate') IS NULL
    ALTER TABLE trading.Execution ADD ExchangeRateDate DATE NULL;
IF COL_LENGTH('trading.Execution', 'TradeValueReporting') IS NULL
    ALTER TABLE trading.Execution ADD TradeValueReporting DECIMAL(19,4) NULL;
IF COL_LENGTH('trading.Execution', 'CommissionReporting') IS NULL
    ALTER TABLE trading.Execution ADD CommissionReporting DECIMAL(19,4) NULL;
GO

UPDATE execution_row
SET
    TradeCurrency = instrument.Currency,
    ReportingCurrency = 'EUR',
    ExchangeRateToReporting = rate_data.ExchangeRate,
    ExchangeRateDate = CAST(execution_row.ExecutedAt AS DATE),
    TradeValueReporting = ROUND
    (
        execution_row.ExecutedQuantity * execution_row.ExecutionPrice
        * rate_data.ExchangeRate,
        4
    ),
    CommissionReporting = ROUND(ISNULL(commission.TotalCommission, 0) * rate_data.ExchangeRate, 4)
FROM trading.Execution execution_row
INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
INNER JOIN trading.Instrument instrument ON instrument.InstrumentId = order_row.InstrumentId
CROSS APPLY
(
    SELECT core.fn_GetExchangeRate
        (instrument.Currency, 'EUR', CAST(execution_row.ExecutedAt AS DATE)) AS ExchangeRate
) rate_data
OUTER APPLY
(
    SELECT SUM(Amount) AS TotalCommission
    FROM trading.Commission
    WHERE ExecutionId = execution_row.ExecutionId
) commission
WHERE execution_row.TradeCurrency IS NULL
   OR execution_row.ReportingCurrency IS NULL
   OR execution_row.ExchangeRateToReporting IS NULL
   OR execution_row.ExchangeRateDate IS NULL
   OR execution_row.TradeValueReporting IS NULL
   OR execution_row.CommissionReporting IS NULL;
GO

IF EXISTS
(
    SELECT 1 FROM trading.Execution
    WHERE TradeCurrency IS NULL OR ReportingCurrency IS NULL
       OR ExchangeRateToReporting IS NULL OR ExchangeRateDate IS NULL
       OR TradeValueReporting IS NULL OR CommissionReporting IS NULL
)
    THROW 54001, N'Nu toate execuțiile au putut fi convertite în EUR.', 1;
GO

ALTER TABLE trading.Execution ALTER COLUMN TradeCurrency CHAR(3) NOT NULL;
ALTER TABLE trading.Execution ALTER COLUMN ReportingCurrency CHAR(3) NOT NULL;
ALTER TABLE trading.Execution ALTER COLUMN ExchangeRateToReporting DECIMAL(19,10) NOT NULL;
ALTER TABLE trading.Execution ALTER COLUMN ExchangeRateDate DATE NOT NULL;
ALTER TABLE trading.Execution ALTER COLUMN TradeValueReporting DECIMAL(19,4) NOT NULL;
ALTER TABLE trading.Execution ALTER COLUMN CommissionReporting DECIMAL(19,4) NOT NULL;
GO

IF OBJECT_ID('trading.FK_Execution_TradeCurrency', 'F') IS NULL
    ALTER TABLE trading.Execution ADD CONSTRAINT FK_Execution_TradeCurrency
        FOREIGN KEY (TradeCurrency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.FK_Execution_ReportingCurrency', 'F') IS NULL
    ALTER TABLE trading.Execution ADD CONSTRAINT FK_Execution_ReportingCurrency
        FOREIGN KEY (ReportingCurrency) REFERENCES core.Currency(CurrencyCode);
IF OBJECT_ID('trading.CK_Execution_ExchangeRate', 'C') IS NULL
    ALTER TABLE trading.Execution ADD CONSTRAINT CK_Execution_ExchangeRate
        CHECK (ExchangeRateToReporting > 0);
IF OBJECT_ID('trading.CK_Execution_ReportingValues', 'C') IS NULL
    ALTER TABLE trading.Execution ADD CONSTRAINT CK_Execution_ReportingValues
        CHECK (TradeValueReporting > 0 AND CommissionReporting >= 0);
GO

CREATE OR ALTER PROCEDURE core.usp_ConvertCurrency
    @Amount DECIMAL(19,4),
    @SourceCurrency CHAR(3),
    @TargetCurrency CHAR(3) = 'EUR',
    @RateDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @RateDate = ISNULL(@RateDate, CAST(SYSUTCDATETIME() AS DATE));

    DECLARE @ExchangeRate DECIMAL(19,10) =
        core.fn_GetExchangeRate(@SourceCurrency, @TargetCurrency, @RateDate);

    IF @ExchangeRate IS NULL
        THROW 54002, N'Nu există un curs valutar pentru data și perechea solicitate.', 1;

    SELECT
        @Amount AS OriginalAmount,
        UPPER(@SourceCurrency) AS SourceCurrency,
        @ExchangeRate AS ExchangeRate,
        ROUND(@Amount * @ExchangeRate, 4) AS ConvertedAmount,
        UPPER(@TargetCurrency) AS TargetCurrency,
        @RateDate AS RateDate;
END;
GO

PRINT N'Conversia valutară cu EUR drept valută de raportare a fost configurată.';
GO
