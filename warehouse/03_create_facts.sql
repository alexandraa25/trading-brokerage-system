USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   DW #3 - Creează tabelele de fapte

   Tabel de fapte:
       dw.FactTrade

   Granularitate:
       Un rând pentru fiecare execuție
   ============================================================ */

CREATE TABLE dw.FactTrade
(
    TradeKey       BIGINT IDENTITY(1,1) NOT NULL,

    /* Chei de dimensiune */

    DateKey        INT NOT NULL,
    CustomerKey    INT NOT NULL,
    AccountKey     INT NOT NULL,
    InstrumentKey  INT NOT NULL,

    /* Chei degenerate/sursă */

    OrderId        BIGINT NOT NULL,
    ExecutionId    BIGINT NOT NULL,

    /* Atributele tranzacției */

    Side           VARCHAR(4) NOT NULL,
    OrderType      VARCHAR(10) NOT NULL,

    /* Măsuri */

    ExecutedQuantity DECIMAL(19,8) NOT NULL,
    ExecutionPrice   DECIMAL(19,8) NOT NULL,

    TradeValue AS
    (
        ExecutedQuantity * ExecutionPrice
    ) PERSISTED,

    CommissionAmount DECIMAL(19,4) NOT NULL,

    /* Marcaj temporal */

    ExecutedAt     DATETIME2(3) NOT NULL,

    DWCreatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_FactTrade_DWCreatedAt
        DEFAULT SYSUTCDATETIME(),


    CONSTRAINT PK_FactTrade
        PRIMARY KEY (TradeKey),


    CONSTRAINT FK_FactTrade_Date
        FOREIGN KEY (DateKey)
        REFERENCES dw.DimDate(DateKey),


    CONSTRAINT FK_FactTrade_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES dw.DimCustomer(CustomerKey),


    CONSTRAINT FK_FactTrade_Account
        FOREIGN KEY (AccountKey)
        REFERENCES dw.DimAccount(AccountKey),


    CONSTRAINT FK_FactTrade_Instrument
        FOREIGN KEY (InstrumentKey)
        REFERENCES dw.DimInstrument(InstrumentKey),


    CONSTRAINT UQ_FactTrade_ExecutionId
        UNIQUE (ExecutionId),


    CONSTRAINT CK_FactTrade_Quantity
        CHECK (ExecutedQuantity > 0),


    CONSTRAINT CK_FactTrade_Price
        CHECK (ExecutionPrice > 0),


    CONSTRAINT CK_FactTrade_Commission
        CHECK (CommissionAmount >= 0),


    CONSTRAINT CK_FactTrade_Side
        CHECK (Side IN ('BUY', 'SELL'))
);
GO


PRINT N'FactTrade a fost creat cu succes.';
GO


SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
WHERE s.name = 'dw'
ORDER BY t.name;
