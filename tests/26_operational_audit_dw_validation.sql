USE BrokerageDW;
GO

/* Verificări read-only pentru modelul analitic al auditului operațional. */
IF OBJECT_ID('dw.DimApplicationUser', 'U') IS NULL
    THROW 56031, N'Lipsește DimApplicationUser. Rulează warehouse/19_operational_audit_analytics.sql.', 1;
IF OBJECT_ID('dw.FactOperationalAudit', 'U') IS NULL
    THROW 56032, N'Lipsește FactOperationalAudit. Rulează warehouse/19_operational_audit_analytics.sql.', 1;
IF OBJECT_ID('dw.vwPowerBiOperationalAudit', 'V') IS NULL
    THROW 56033, N'Lipsește vizualizarea Power BI pentru auditul operațional.', 1;
IF EXISTS
(
    SELECT SourceType, SourceAuditId
    FROM dw.FactOperationalAudit
    GROUP BY SourceType, SourceAuditId
    HAVING COUNT(*) > 1
)
    THROW 56034, N'Există evenimente operaționale duplicate în depozit.', 1;
IF EXISTS
(
    SELECT 1
    FROM dw.FactOperationalAudit audit
    LEFT JOIN dw.DimDate d ON d.DateKey=audit.DateKey
    WHERE d.DateKey IS NULL
)
    THROW 56035, N'Un eveniment operațional nu are dată validă.', 1;

PRINT N'Validarea depozitului pentru audit operațional a trecut.';
GO
