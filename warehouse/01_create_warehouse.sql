/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   Date Warehouse #1 - Creează BrokerageDW

   Scop:
       Creează o bază de date analitică separată.

   Sistem sursă:
       BrokerageDB

   Destinație:
       BrokerageDW
   ============================================================ */

USE master;
GO

IF DB_ID('BrokerageDW') IS NULL
BEGIN
    CREATE DATABASE BrokerageDW;
END;
GO


USE BrokerageDW;
GO


/* ============================================================
   Creează schemele depozitului de date
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'dw'
)
BEGIN
    EXEC('CREATE SCHEMA dw');
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'etl'
)
BEGIN
    EXEC('CREATE SCHEMA etl');
END;
GO


PRINT N'BrokerageDW a fost creată cu succes.';
GO




SELECT
    DB_NAME() AS CurrentDatabase;

SELECT
    name AS SchemaName
FROM sys.schemas
WHERE name IN ('dw', 'etl')
ORDER BY name;
