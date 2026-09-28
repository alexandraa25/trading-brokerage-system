USE BrokerageDW;
GO

/* Verificări read-only pentru analiza ordinelor cu termen de valabilitate. */
IF OBJECT_ID('dw.FactOrderLifecycle', 'U') IS NULL
    THROW 56021, N'Lipsește FactOrderLifecycle. Rulează scripturile depozitului de date.', 1;
IF COL_LENGTH('dw.FactOrderLifecycle', 'TimeInForce') IS NULL
    THROW 56022, N'Lipsește TimeInForce. Rulează warehouse/18_upgrade_fact_order_expiration.sql.', 1;
IF COL_LENGTH('dw.FactOrderLifecycle', 'ExpiresAt') IS NULL
    THROW 56023, N'Lipsește ExpiresAt. Rulează warehouse/18_upgrade_fact_order_expiration.sql.', 1;
IF OBJECT_ID('dw.vwPowerBiOrderLifecycle', 'V') IS NULL
    THROW 56024, N'Lipsește vizualizarea Power BI pentru ciclul ordinelor.', 1;
IF NOT EXISTS
(
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.views v ON v.object_id = c.object_id
    INNER JOIN sys.schemas s ON s.schema_id = v.schema_id
    WHERE s.name = 'dw' AND v.name = 'vwPowerBiOrderLifecycle'
      AND c.name IN ('Valabilitate', 'ExpiraLa')
    GROUP BY v.object_id
    HAVING COUNT(DISTINCT c.name) = 2
)
    THROW 56025, N'Vizualizarea Power BI nu expune valabilitatea și expirarea.', 1;
IF EXISTS
(
    SELECT 1
    FROM dw.FactOrderLifecycle
    WHERE OrderStatus = 'Expired' AND (ResolvedAt IS NULL OR ResolutionDateKey IS NULL)
)
    THROW 56026, N'Există ordine expirate fără moment de soluționare în depozit.', 1;

PRINT N'Validarea depozitului pentru expirarea ordinelor a trecut.';
GO
