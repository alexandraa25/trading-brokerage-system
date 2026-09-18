USE BrokerageDW;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   DW #2 - Creează dimensiunile

   Dimensiuni:
       dw.DimDate
       dw.DimCustomer
       dw.DimAccount
       dw.DimInstrument
   ============================================================ */


/* ============================================================
   1. DimDate
   ============================================================ */

CREATE TABLE dw.DimDate
(
    DateKey       INT NOT NULL,
    FullDate      DATE NOT NULL,

    DayNumber     TINYINT NOT NULL,
    DayName       VARCHAR(20) NOT NULL,

    MonthNumber   TINYINT NOT NULL,
    MonthName     VARCHAR(20) NOT NULL,

    QuarterNumber TINYINT NOT NULL,
    YearNumber    SMALLINT NOT NULL,

    YearMonth     CHAR(7) NOT NULL,

    IsWeekend     BIT NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY (DateKey),

    CONSTRAINT UQ_DimDate_FullDate
        UNIQUE (FullDate)
);
GO


/* ============================================================
   2. DimCustomer

   CustomerKey = cheie surogat
   CustomerId  = cheie sursă/de business din OLTP
   ============================================================ */

CREATE TABLE dw.DimCustomer
(
    CustomerKey     INT IDENTITY(1,1) NOT NULL,

    CustomerId      BIGINT NOT NULL,
    CustomerTypeId  TINYINT NOT NULL,

    FirstName       VARCHAR(100) NOT NULL,
    LastName        VARCHAR(100) NOT NULL,
    FullName        VARCHAR(201) NOT NULL,

    Email           VARCHAR(255) NOT NULL,

    DateOfBirth     DATE NULL,

    CustomerStatus  VARCHAR(20) NOT NULL,

    SourceCreatedAt DATETIME2(3) NOT NULL,
    SourceUpdatedAt DATETIME2(3) NOT NULL,

    DWCreatedAt     DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimCustomer_DWCreatedAt
        DEFAULT SYSUTCDATETIME(),

    DWUpdatedAt     DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimCustomer_DWUpdatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_DimCustomer
        PRIMARY KEY (CustomerKey),

    CONSTRAINT UQ_DimCustomer_CustomerId
        UNIQUE (CustomerId)
);
GO


/* ============================================================
   3. DimAccount
   ============================================================ */

CREATE TABLE dw.DimAccount
(
    AccountKey       INT IDENTITY(1,1) NOT NULL,

    AccountId        BIGINT NOT NULL,
    CustomerId       BIGINT NOT NULL,

    AccountNumber    VARCHAR(30) NOT NULL,
    Currency         CHAR(3) NOT NULL,
    AccountStatus    VARCHAR(20) NOT NULL,

    SourceCreatedAt  DATETIME2(3) NOT NULL,
    ClosedAt         DATETIME2(3) NULL,

    DWCreatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimAccount_DWCreatedAt
        DEFAULT SYSUTCDATETIME(),

    DWUpdatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimAccount_DWUpdatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_DimAccount
        PRIMARY KEY (AccountKey),

    CONSTRAINT UQ_DimAccount_AccountId
        UNIQUE (AccountId)
);
GO


/* ============================================================
   4. DimInstrument

   Atributele pieței sunt denormalizate în dimensiune.
   Aceasta este o decizie intenționată de modelare dimensională.
   ============================================================ */

CREATE TABLE dw.DimInstrument
(
    InstrumentKey       INT IDENTITY(1,1) NOT NULL,

    InstrumentId        BIGINT NOT NULL,

    Symbol              VARCHAR(20) NOT NULL,
    InstrumentName      VARCHAR(200) NOT NULL,
    InstrumentType      VARCHAR(20) NOT NULL,
    InstrumentCurrency  CHAR(3) NOT NULL,

    MarketId            INT NOT NULL,
    MarketCode          VARCHAR(20) NOT NULL,
    MarketName          VARCHAR(100) NOT NULL,
    MarketCountryCode   CHAR(2) NOT NULL,
    MarketCurrency      CHAR(3) NOT NULL,

    IsActive            BIT NOT NULL,

    SourceCreatedAt     DATETIME2(3) NOT NULL,

    DWCreatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimInstrument_DWCreatedAt
        DEFAULT SYSUTCDATETIME(),

    DWUpdatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_DimInstrument_DWUpdatedAt
        DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_DimInstrument
        PRIMARY KEY (InstrumentKey),

    CONSTRAINT UQ_DimInstrument_InstrumentId
        UNIQUE (InstrumentId)
);
GO


PRINT N'Dimensiunile depozitului de date au fost create cu succes.';
GO



SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;


SELECT
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
INNER JOIN sys.partitions p
    ON p.object_id = t.object_id
   AND p.index_id IN (0,1)
WHERE s.name = 'dw'
GROUP BY t.name
ORDER BY t.name;
