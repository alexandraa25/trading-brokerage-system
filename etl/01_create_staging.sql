USE BrokerageDB;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   ETL #1 - Creează stratul intermediar
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'staging'
)
BEGIN
    EXEC('CREATE SCHEMA staging');
END;
GO


/* ============================================================
   1. Client
   Sursă: core.Customer
   ============================================================ */

CREATE TABLE staging.Customer
(
    CustomerId     BIGINT       NOT NULL,
    CustomerTypeId TINYINT      NOT NULL,
    FirstName      VARCHAR(100) NOT NULL,
    LastName       VARCHAR(100) NOT NULL,
    Email          VARCHAR(255) NOT NULL,
    Phone          VARCHAR(30)  NULL,
    DateOfBirth    DATE         NULL,
    Status         VARCHAR(20)  NOT NULL,
    CreatedAt      DATETIME2(3) NOT NULL,
    UpdatedAt      DATETIME2(3) NOT NULL,

    ExtractedAt    DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   2. Cont
   Sursă: core.Account
   ============================================================ */

CREATE TABLE staging.Account
(
    AccountId     BIGINT       NOT NULL,
    CustomerId    BIGINT       NOT NULL,
    AccountNumber VARCHAR(30)  NOT NULL,
    Currency      CHAR(3)      NOT NULL,
    Status        VARCHAR(20)  NOT NULL,
    CreatedAt     DATETIME2(3) NOT NULL,
    UpdatedAt     DATETIME2(3) NOT NULL,
    ClosedAt      DATETIME2(3) NULL,

    ExtractedAt   DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   3. Market
   Sursă: trading.Market
   ============================================================ */

CREATE TABLE staging.Market
(
    MarketId    INT          NOT NULL,
    MarketCode  VARCHAR(20)  NOT NULL,
    MarketName  VARCHAR(100) NOT NULL,
    CountryCode CHAR(2)      NOT NULL,
    Currency    CHAR(3)      NOT NULL,
    IsActive    BIT          NOT NULL,
    CreatedAt   DATETIME2(3) NOT NULL,
    UpdatedAt   DATETIME2(3) NOT NULL,

    ExtractedAt DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   4. Instrument
   Sursă: trading.Instrument
   ============================================================ */

CREATE TABLE staging.Instrument
(
    InstrumentId   BIGINT       NOT NULL,
    MarketId       INT          NOT NULL,
    IssuerId       INT          NOT NULL,
    Symbol         VARCHAR(20)  NOT NULL,
    InstrumentName VARCHAR(200) NOT NULL,
    InstrumentType VARCHAR(20)  NOT NULL,
    Currency       CHAR(3)      NOT NULL,
    IsActive       BIT          NOT NULL,
    CreatedAt      DATETIME2(3) NOT NULL,
    UpdatedAt      DATETIME2(3) NOT NULL,

    ExtractedAt    DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   5. Ordin
   Sursă: trading.Order
   ============================================================ */

CREATE TABLE staging.[Order]
(
    OrderId      BIGINT        NOT NULL,
    AccountId    BIGINT        NOT NULL,
    InstrumentId BIGINT        NOT NULL,
    Side         VARCHAR(4)    NOT NULL,
    OrderType    VARCHAR(10)   NOT NULL,
    Quantity     DECIMAL(19,8) NOT NULL,
    LimitPrice   DECIMAL(19,8) NULL,
    StopPrice    DECIMAL(19,8) NULL,
    OriginalQuantity DECIMAL(19,8) NULL,
    CancelledQuantity DECIMAL(19,8) NOT NULL DEFAULT (0),
    Status       VARCHAR(20)   NOT NULL,
    CreatedAt    DATETIME2(3)  NOT NULL,
    UpdatedAt    DATETIME2(3)  NOT NULL,

    ExtractedAt  DATETIME2(3)  NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   6. Execuție
   Sursă: trading.Execution
   ============================================================ */

CREATE TABLE staging.Execution
(
    ExecutionId      BIGINT        NOT NULL,
    OrderId          BIGINT        NOT NULL,
    ExecutedQuantity DECIMAL(19,8) NOT NULL,
    ExecutionPrice   DECIMAL(19,8) NOT NULL,
    ExecutedAt       DATETIME2(3)  NOT NULL,
    CreatedAt        DATETIME2(3)  NOT NULL,
    TradeCurrency    CHAR(3)       NOT NULL,
    ReportingCurrency CHAR(3)      NOT NULL,
    ExchangeRateToReporting DECIMAL(19,10) NOT NULL,
    ExchangeRateDate DATE          NOT NULL,
    ExchangeRateSource VARCHAR(50) NOT NULL,
    TradeValueReporting DECIMAL(19,4) NOT NULL,
    CommissionReporting DECIMAL(19,4) NOT NULL,

    ExtractedAt      DATETIME2(3)  NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ============================================================
   7. CashTransaction
   Sursă: trading.CashTransaction
   ============================================================ */

CREATE TABLE staging.CashTransaction
(
    CashTransactionId BIGINT        NOT NULL,
    CashAccountId     BIGINT        NOT NULL,
    TransactionType   VARCHAR(20)   NOT NULL,
    Amount            DECIMAL(19,4) NOT NULL,
    Currency          CHAR(3)       NOT NULL,
    ReferenceType     VARCHAR(30)   NULL,
    ReferenceId       BIGINT        NULL,
    Description       VARCHAR(500)  NULL,
    CreatedAt         DATETIME2(3)  NOT NULL,

    ExtractedAt       DATETIME2(3)  NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


PRINT N'Stratul staging a fost creat cu succes.';
GO


SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name = 'staging'
ORDER BY t.name;


SELECT COUNT(*) AS CustomerRows
FROM staging.Customer;

SELECT COUNT(*) AS OrderRowss
FROM staging.[Order];

SELECT COUNT(*) AS ExecutionRows
FROM staging.Execution;
