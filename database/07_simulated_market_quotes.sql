/* Cotații simulate pentru aplicația demonstrativă de portofoliu. */
IF OBJECT_ID('trading.MarketQuote', 'U') IS NULL
BEGIN
    CREATE TABLE trading.MarketQuote
    (
        MarketQuoteId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MarketQuote PRIMARY KEY,
        InstrumentId BIGINT NOT NULL CONSTRAINT FK_MarketQuote_Instrument
            FOREIGN KEY REFERENCES trading.Instrument(InstrumentId),
        QuoteDate DATE NOT NULL,
        MarketPrice DECIMAL(19,8) NOT NULL CONSTRAINT CK_MarketQuote_Price CHECK (MarketPrice > 0),
        QuoteCurrency CHAR(3) NOT NULL CONSTRAINT FK_MarketQuote_Currency
            FOREIGN KEY REFERENCES core.Currency(CurrencyCode),
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT DF_MarketQuote_Source DEFAULT ('SIMULATED_DAILY'),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_MarketQuote_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_MarketQuote UNIQUE (InstrumentId, QuoteDate)
    );
END;
GO

CREATE OR ALTER PROCEDURE trading.usp_RefreshSimulatedMarketQuotes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @QuoteDate DATE = CAST(SYSUTCDATETIME() AS DATE);

    MERGE trading.MarketQuote AS target
    USING
    (
        SELECT i.InstrumentId, i.Currency,
               CAST(ROUND(20 + (i.InstrumentId * 7.31)
                    + (ABS(CHECKSUM(@QuoteDate, i.InstrumentId)) % 2500) / 100.0, 8) AS DECIMAL(19,8)) AS MarketPrice
        FROM trading.Instrument i
        WHERE i.IsActive = 1
    ) AS source
    ON target.InstrumentId = source.InstrumentId AND target.QuoteDate = @QuoteDate
    WHEN MATCHED THEN UPDATE SET MarketPrice = source.MarketPrice, QuoteCurrency = source.Currency,
        SourceSystem = 'SIMULATED_DAILY', CreatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (InstrumentId, QuoteDate, MarketPrice, QuoteCurrency, SourceSystem)
        VALUES (source.InstrumentId, @QuoteDate, source.MarketPrice, source.Currency, 'SIMULATED_DAILY');
END;
GO

EXEC trading.usp_RefreshSimulatedMarketQuotes;
GO
