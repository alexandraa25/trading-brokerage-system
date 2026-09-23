USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   DW #8 - FactCashTransaction

   Granularitate:
       un rând pentru fiecare mișcare de numerar din sursă.

   Păstrează suma în moneda inițială și echivalentul istoric în
   EUR. Pentru conversii se folosește cursul salvat chiar pe
   conversie, astfel încât rapoartele nu se modifică ulterior.
   ============================================================ */

IF OBJECT_ID('dw.FactCashTransaction', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactCashTransaction
    (
        CashTransactionKey BIGINT IDENTITY(1,1) NOT NULL,

        DateKey            INT NOT NULL,
        ExchangeRateDateKey INT NOT NULL,
        CustomerKey        INT NOT NULL,
        AccountKey         INT NOT NULL,
        CurrencyKey        INT NOT NULL,

        CashTransactionId  BIGINT NOT NULL,
        CashAccountId      BIGINT NOT NULL,
        TransactionType    VARCHAR(20) NOT NULL,
        ReferenceType      VARCHAR(30) NULL,
        ReferenceId        BIGINT NULL,

        AmountOriginal     DECIMAL(19,4) NOT NULL,
        ExchangeRateToEur  DECIMAL(19,10) NOT NULL,
        ExchangeRateSource VARCHAR(50) NOT NULL,
        AmountEur          DECIMAL(19,4) NOT NULL,
        CreatedAt          DATETIME2(3) NOT NULL,

        DWCreatedAt        DATETIME2(3) NOT NULL
            CONSTRAINT DF_FactCashTransaction_DWCreatedAt
            DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt        DATETIME2(3) NOT NULL
            CONSTRAINT DF_FactCashTransaction_DWUpdatedAt
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_FactCashTransaction
            PRIMARY KEY (CashTransactionKey),
        CONSTRAINT UQ_FactCashTransaction_CashTransactionId
            UNIQUE (CashTransactionId),
        CONSTRAINT FK_FactCashTransaction_Date
            FOREIGN KEY (DateKey) REFERENCES dw.DimDate(DateKey),
        CONSTRAINT FK_FactCashTransaction_ExchangeRateDate
            FOREIGN KEY (ExchangeRateDateKey) REFERENCES dw.DimDate(DateKey),
        CONSTRAINT FK_FactCashTransaction_Customer
            FOREIGN KEY (CustomerKey) REFERENCES dw.DimCustomer(CustomerKey),
        CONSTRAINT FK_FactCashTransaction_Account
            FOREIGN KEY (AccountKey) REFERENCES dw.DimAccount(AccountKey),
        CONSTRAINT FK_FactCashTransaction_Currency
            FOREIGN KEY (CurrencyKey) REFERENCES dw.DimCurrency(CurrencyKey),
        CONSTRAINT CK_FactCashTransaction_Amount
            CHECK (AmountOriginal <> 0),
        CONSTRAINT CK_FactCashTransaction_ExchangeRate
            CHECK (ExchangeRateToEur > 0)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactCashTransaction')
      AND name = 'IX_FactCashTransaction_Customer_Date'
)
    CREATE INDEX IX_FactCashTransaction_Customer_Date
        ON dw.FactCashTransaction(CustomerKey, DateKey)
        INCLUDE (AccountKey, CurrencyKey, TransactionType, AmountEur);
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactCashTransaction')
      AND name = 'IX_FactCashTransaction_Account_Date'
)
    CREATE INDEX IX_FactCashTransaction_Account_Date
        ON dw.FactCashTransaction(AccountKey, DateKey)
        INCLUDE (CurrencyKey, TransactionType, AmountOriginal, AmountEur);
GO

PRINT N'FactCashTransaction și indecșii analitici au fost creați cu succes.';
GO
