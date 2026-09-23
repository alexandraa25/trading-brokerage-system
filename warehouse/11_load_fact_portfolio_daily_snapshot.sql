USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   DW #11 - Încarcă FactPortfolioDailySnapshot

   Sursă: BrokerageDB.reporting.PortfolioDailySnapshot
   Strategie: incrementală și idempotentă după identificatorul sursă.
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @RowsInserted BIGINT = 0;
DECLARE @RowsUpdated BIGINT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID('tempdb..#SourcePortfolioSnapshot') IS NOT NULL
        DROP TABLE #SourcePortfolioSnapshot;

    SELECT
        CONVERT(INT, CONVERT(CHAR(8), source_row.SnapshotDate, 112)) AS DateKey,
        customer.CustomerKey,
        account.AccountKey,
        source_row.PortfolioDailySnapshotId,
        source_row.InvestedValueEur,
        source_row.PositionsValueEur,
        source_row.CashValueEur,
        source_row.TotalValueEur,
        source_row.SourceSystem,
        source_row.SnapshotDate,
        source_row.CreatedAt AS SourceCreatedAt
    INTO #SourcePortfolioSnapshot
    FROM BrokerageDB.reporting.PortfolioDailySnapshot AS source_row
    INNER JOIN dw.DimAccount AS account
        ON account.AccountId = source_row.AccountId
    INNER JOIN dw.DimCustomer AS customer
        ON customer.CustomerId = account.CustomerId;

    IF EXISTS
    (
        SELECT 1
        FROM #SourcePortfolioSnapshot AS source_row
        LEFT JOIN dw.DimDate AS snapshot_date
            ON snapshot_date.DateKey = source_row.DateKey
        WHERE snapshot_date.DateKey IS NULL
    )
        THROW 54040, N'Calendarul dimensional nu acoperă toate snapshoturile de portofoliu.', 1;

    UPDATE target
    SET
        DateKey = source_row.DateKey,
        CustomerKey = source_row.CustomerKey,
        AccountKey = source_row.AccountKey,
        InvestedValueEur = source_row.InvestedValueEur,
        PositionsValueEur = source_row.PositionsValueEur,
        CashValueEur = source_row.CashValueEur,
        TotalValueEur = source_row.TotalValueEur,
        SourceSystem = source_row.SourceSystem,
        SnapshotDate = source_row.SnapshotDate,
        SourceCreatedAt = source_row.SourceCreatedAt,
        DWUpdatedAt = SYSUTCDATETIME()
    FROM dw.FactPortfolioDailySnapshot AS target
    INNER JOIN #SourcePortfolioSnapshot AS source_row
        ON source_row.PortfolioDailySnapshotId = target.PortfolioDailySnapshotId
    WHERE target.DateKey <> source_row.DateKey
       OR target.CustomerKey <> source_row.CustomerKey
       OR target.AccountKey <> source_row.AccountKey
       OR target.InvestedValueEur <> source_row.InvestedValueEur
       OR target.PositionsValueEur <> source_row.PositionsValueEur
       OR target.CashValueEur <> source_row.CashValueEur
       OR target.TotalValueEur <> source_row.TotalValueEur
       OR target.SourceSystem <> source_row.SourceSystem
       OR target.SnapshotDate <> source_row.SnapshotDate
       OR target.SourceCreatedAt <> source_row.SourceCreatedAt;

    SET @RowsUpdated = @@ROWCOUNT;

    INSERT INTO dw.FactPortfolioDailySnapshot
    (
        DateKey, CustomerKey, AccountKey, PortfolioDailySnapshotId,
        InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur,
        SourceSystem, SnapshotDate, SourceCreatedAt
    )
    SELECT
        DateKey, CustomerKey, AccountKey, PortfolioDailySnapshotId,
        InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur,
        SourceSystem, SnapshotDate, SourceCreatedAt
    FROM #SourcePortfolioSnapshot AS source_row
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.FactPortfolioDailySnapshot AS target
        WHERE target.PortfolioDailySnapshotId = source_row.PortfolioDailySnapshotId
    );

    SET @RowsInserted = @@ROWCOUNT;

    COMMIT TRANSACTION;

    PRINT N'Încărcarea FactPortfolioDailySnapshot s-a finalizat cu succes.';
    PRINT CONCAT('Rânduri inserate: ', @RowsInserted, N'; rânduri actualizate: ', @RowsUpdated, N'.');
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
