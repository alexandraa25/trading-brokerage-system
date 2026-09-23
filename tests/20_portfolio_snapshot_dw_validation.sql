USE BrokerageDW;
GO

/* Verificări read-only pentru evoluția zilnică a portofoliilor. */

SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM dw.FactPortfolioDailySnapshot) <>
   (SELECT COUNT(*) FROM BrokerageDB.reporting.PortfolioDailySnapshot)
    THROW 55020, N'Numărul snapshoturilor din depozit diferă de sursă.', 1;

IF EXISTS
(
    SELECT AccountKey, DateKey
    FROM dw.FactPortfolioDailySnapshot
    GROUP BY AccountKey, DateKey
    HAVING COUNT(*) > 1
)
    THROW 55021, N'Există snapshoturi zilnice duplicate pentru același cont.', 1;

IF EXISTS
(
    SELECT 1
    FROM dw.FactPortfolioDailySnapshot
    WHERE InvestedValueEur < 0
       OR PositionsValueEur < 0
       OR CashValueEur < 0
       OR TotalValueEur < 0
)
    THROW 55022, N'Există valori negative în snapshoturile de portofoliu.', 1;

IF EXISTS
(
    SELECT 1
    FROM BrokerageDB.reporting.PortfolioDailySnapshot AS source_row
    LEFT JOIN dw.FactPortfolioDailySnapshot AS fact
        ON fact.PortfolioDailySnapshotId = source_row.PortfolioDailySnapshotId
    WHERE fact.PortfolioDailySnapshotId IS NULL
       OR fact.TotalValueEur <> source_row.TotalValueEur
)
    THROW 55023, N'Valoarea totală a snapshotului nu corespunde sursei.', 1;

SELECT
    snapshot_date.YearNumber,
    snapshot_date.MonthNumber,
    COUNT(*) AS NumarSnapshoturi,
    SUM(fact.TotalValueEur) AS ValoareTotalaEur
FROM dw.FactPortfolioDailySnapshot AS fact
INNER JOIN dw.DimDate AS snapshot_date
    ON snapshot_date.DateKey = fact.DateKey
GROUP BY snapshot_date.YearNumber, snapshot_date.MonthNumber
ORDER BY snapshot_date.YearNumber, snapshot_date.MonthNumber;

PRINT N'Validarea FactPortfolioDailySnapshot s-a finalizat cu succes.';
GO
