/* Istoric zilnic al valorii portofoliului, exprimat în EUR. */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reporting')
    EXEC('CREATE SCHEMA reporting');
GO

IF OBJECT_ID('reporting.PortfolioDailySnapshot', 'U') IS NULL
BEGIN
    CREATE TABLE reporting.PortfolioDailySnapshot
    (
        PortfolioDailySnapshotId BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_PortfolioDailySnapshot PRIMARY KEY,
        AccountId BIGINT NOT NULL
            CONSTRAINT FK_PortfolioDailySnapshot_Account
            FOREIGN KEY REFERENCES core.Account(AccountId),
        SnapshotDate DATE NOT NULL,
        InvestedValueEur DECIMAL(19,4) NOT NULL,
        PositionsValueEur DECIMAL(19,4) NOT NULL,
        CashValueEur DECIMAL(19,4) NOT NULL,
        TotalValueEur DECIMAL(19,4) NOT NULL,
        SourceSystem VARCHAR(50) NOT NULL
            CONSTRAINT DF_PortfolioDailySnapshot_Source DEFAULT ('SIMULATED_DAILY + ECB_REFERENCE'),
        CreatedAt DATETIME2(3) NOT NULL
            CONSTRAINT DF_PortfolioDailySnapshot_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_PortfolioDailySnapshot UNIQUE (AccountId, SnapshotDate)
    );
END;
GO

CREATE OR ALTER PROCEDURE reporting.usp_CapturePortfolioDailySnapshot
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SnapshotDate DATE = CAST(SYSUTCDATETIME() AS DATE);

    MERGE reporting.PortfolioDailySnapshot AS target
    USING
    (
        SELECT a.AccountId,
               CAST(ISNULL(SUM(p.Quantity * p.AveragePrice * ISNULL(positionRate.MidRate, 1)), 0) AS DECIMAL(19,4)) AS InvestedValueEur,
               CAST(ISNULL(SUM(p.Quantity * quote.MarketPrice * ISNULL(positionRate.MidRate, 1)), 0) AS DECIMAL(19,4)) AS PositionsValueEur,
               CAST(ISNULL(cash.CashValueEur, 0) AS DECIMAL(19,4)) AS CashValueEur
        FROM core.Account a
        LEFT JOIN trading.Position p ON p.AccountId = a.AccountId AND p.Quantity > 0
        LEFT JOIN trading.Instrument i ON i.InstrumentId = p.InstrumentId
        OUTER APPLY (SELECT TOP 1 MarketPrice FROM trading.MarketQuote WHERE InstrumentId = p.InstrumentId ORDER BY QuoteDate DESC) quote
        OUTER APPLY (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = i.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) positionRate
        OUTER APPLY
        (
            SELECT SUM(ca.AvailableBalance * ISNULL(cashRate.MidRate, 1)) AS CashValueEur
            FROM core.CashAccount ca
            OUTER APPLY (SELECT TOP 1 MidRate FROM core.ExchangeRate WHERE SourceCurrency = ca.Currency AND TargetCurrency = 'EUR' ORDER BY RateDate DESC) cashRate
            WHERE ca.AccountId = a.AccountId
        ) cash
        WHERE a.Status = 'Active'
        GROUP BY a.AccountId, cash.CashValueEur
    ) AS source
    ON target.AccountId = source.AccountId AND target.SnapshotDate = @SnapshotDate
    WHEN MATCHED THEN UPDATE SET InvestedValueEur = source.InvestedValueEur,
        PositionsValueEur = source.PositionsValueEur, CashValueEur = source.CashValueEur,
        TotalValueEur = source.PositionsValueEur + source.CashValueEur,
        SourceSystem = 'SIMULATED_DAILY + ECB_REFERENCE', CreatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (AccountId, SnapshotDate, InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur)
        VALUES (source.AccountId, @SnapshotDate, source.InvestedValueEur, source.PositionsValueEur,
                source.CashValueEur, source.PositionsValueEur + source.CashValueEur);
END;
GO

EXEC reporting.usp_CapturePortfolioDailySnapshot;
GO

/* Istoric inițial pentru demonstrație. Capturile ulterioare sunt păstrate zilnic. */
;WITH Dates AS
(
    SELECT DATEADD(DAY, -27, CAST(SYSUTCDATETIME() AS DATE)) AS SnapshotDate
    UNION ALL SELECT DATEADD(DAY, 1, SnapshotDate) FROM Dates
    WHERE SnapshotDate < CAST(SYSUTCDATETIME() AS DATE)
), CurrentSnapshots AS
(
    SELECT AccountId, InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur
    FROM reporting.PortfolioDailySnapshot
    WHERE SnapshotDate = CAST(SYSUTCDATETIME() AS DATE)
)
INSERT INTO reporting.PortfolioDailySnapshot
    (AccountId, SnapshotDate, InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur, SourceSystem)
SELECT snapshot.AccountId, dates.SnapshotDate,
       snapshot.InvestedValueEur,
       CAST(snapshot.PositionsValueEur * (0.94 + (ABS(CHECKSUM(snapshot.AccountId, dates.SnapshotDate)) % 1200) / 10000.0) AS DECIMAL(19,4)),
       snapshot.CashValueEur,
       CAST(snapshot.CashValueEur + snapshot.PositionsValueEur * (0.94 + (ABS(CHECKSUM(snapshot.AccountId, dates.SnapshotDate)) % 1200) / 10000.0) AS DECIMAL(19,4)),
       'DEMO_HISTORY'
FROM CurrentSnapshots snapshot CROSS JOIN Dates dates
WHERE dates.SnapshotDate < CAST(SYSUTCDATETIME() AS DATE)
  AND NOT EXISTS (SELECT 1 FROM reporting.PortfolioDailySnapshot existing WHERE existing.AccountId = snapshot.AccountId AND existing.SnapshotDate = dates.SnapshotDate)
OPTION (MAXRECURSION 100);
GO
