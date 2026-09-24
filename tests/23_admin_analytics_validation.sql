USE BrokerageDW;
GO
SET NOCOUNT ON;

IF OBJECT_ID('dw.vwPowerBiCashFlow', 'V') IS NULL
   OR OBJECT_ID('dw.vwPowerBiPortfolioEvolution', 'V') IS NULL
   OR OBJECT_ID('dw.vwPowerBiOrderLifecycle', 'V') IS NULL
    THROW 55050, N'Lipsește una dintre vizualizările analitice pentru administrator.', 1;

IF NOT EXISTS (SELECT 1 FROM dw.FactPortfolioDailySnapshot)
    THROW 55051, N'Nu există snapshoturi de portofoliu pentru raportare.', 1;

IF NOT EXISTS (SELECT 1 FROM dw.FactKyc)
    THROW 55052, N'Nu există dosare KYC pentru raportare.', 1;

SELECT
    (SELECT COUNT(*) FROM dw.vwPowerBiCashFlow) AS CashFlowRows,
    (SELECT COUNT(*) FROM dw.vwPowerBiPortfolioEvolution) AS PortfolioRows,
    (SELECT COUNT(*) FROM dw.vwPowerBiOrderLifecycle) AS OrderRows,
    (SELECT COUNT(*) FROM dw.FactKyc) AS KycRows;

PRINT N'Validarea rapoartelor administrative s-a finalizat cu succes.';
GO
