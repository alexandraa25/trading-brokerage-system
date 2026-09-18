USE BrokerageDB;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   ETL #3 - Control ETL / marcaj temporal

   Scop:
       - urmărește rulările ETL
       - păstrează marcajul ultimei încărcări reușite
       - permite încărcarea incrementală
       - păstrează numărul de rânduri procesate
       - păstrează erorile ETL
   ============================================================ */


/* ============================================================
   1. Marcaj temporal ETL

   Un rând pentru fiecare entitate sursă.
   LastSuccessfulLoad indică punctul de pornire al încărcării incrementale.
   ============================================================ */

CREATE TABLE staging.ETLWatermark
(
    EntityName         VARCHAR(100) NOT NULL,
    LastSuccessfulLoad DATETIME2(3) NOT NULL,
    UpdatedAt          DATETIME2(3) NOT NULL
        CONSTRAINT DF_ETLWatermark_UpdatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_ETLWatermark
        PRIMARY KEY (EntityName)
);
GO


/* ============================================================
   2. Jurnalul rulărilor ETL

   Un rând pentru fiecare rulare ETL.
   ============================================================ */

CREATE TABLE staging.ETLRunLog
(
    ETLRunId       BIGINT IDENTITY(1,1) NOT NULL,
    EntityName     VARCHAR(100) NOT NULL,

    StartedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_ETLRunLog_StartedAt
        DEFAULT SYSUTCDATETIME(),

    CompletedAt    DATETIME2(3) NULL,

    Status         VARCHAR(20) NOT NULL,

    RowsProcessed  BIGINT NULL,

    ErrorMessage   NVARCHAR(4000) NULL,

    CONSTRAINT PK_ETLRunLog
        PRIMARY KEY (ETLRunId),

    CONSTRAINT CK_ETLRunLog_Status
        CHECK
        (
            Status IN
            (
                'Running',
                'Succeeded',
                'Failed'
            )
        )
);
GO


/* ============================================================
   3. Inițializează marcajele temporale

   1900-01-01 means:
   "Nu a fost efectuată încă nicio încărcare incrementală."
   ============================================================ */

INSERT INTO staging.ETLWatermark
(
    EntityName,
    LastSuccessfulLoad
)
VALUES
    ('Customer',        '19000101'),
    ('Account',         '19000101'),
    ('Market',          '19000101'),
    ('Instrument',      '19000101'),
    ('Order',           '19000101'),
    ('Execution',       '19000101'),
    ('CashTransaction', '19000101');
GO


PRINT N'Tabelele de control ETL au fost create cu succes.';
GO


/* ============================================================
   TEST
   ============================================================ */

SELECT *
FROM staging.ETLWatermark
ORDER BY EntityName;

SELECT *
FROM staging.ETLRunLog;

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name = 'staging'
ORDER BY t.name;
