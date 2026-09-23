USE BrokerageDW;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ============================================================
   DW #10 - FactPortfolioDailySnapshot

   Granularitate:
       un rând pentru fiecare cont de tranzacționare și zi.

   Sursa păstrează valorile în EUR, calculate la capturarea zilnică.
   ============================================================ */

IF OBJECT_ID('dw.FactPortfolioDailySnapshot', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactPortfolioDailySnapshot
    (
        PortfolioDailySnapshotKey BIGINT IDENTITY(1,1) NOT NULL,

        DateKey                   INT NOT NULL,
        CustomerKey               INT NOT NULL,
        AccountKey                INT NOT NULL,
        PortfolioDailySnapshotId  BIGINT NOT NULL,

        InvestedValueEur          DECIMAL(19,4) NOT NULL,
        PositionsValueEur         DECIMAL(19,4) NOT NULL,
        CashValueEur              DECIMAL(19,4) NOT NULL,
        TotalValueEur             DECIMAL(19,4) NOT NULL,
        SourceSystem              VARCHAR(50) NOT NULL,
        SnapshotDate              DATE NOT NULL,
        SourceCreatedAt           DATETIME2(3) NOT NULL,

        DWCreatedAt               DATETIME2(3) NOT NULL
            CONSTRAINT DF_FactPortfolioDailySnapshot_DWCreatedAt
            DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt               DATETIME2(3) NOT NULL
            CONSTRAINT DF_FactPortfolioDailySnapshot_DWUpdatedAt
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_FactPortfolioDailySnapshot
            PRIMARY KEY (PortfolioDailySnapshotKey),
        CONSTRAINT UQ_FactPortfolioDailySnapshot_SourceId
            UNIQUE (PortfolioDailySnapshotId),
        CONSTRAINT UQ_FactPortfolioDailySnapshot_AccountDate
            UNIQUE (AccountKey, DateKey),
        CONSTRAINT FK_FactPortfolioDailySnapshot_Date
            FOREIGN KEY (DateKey) REFERENCES dw.DimDate(DateKey),
        CONSTRAINT FK_FactPortfolioDailySnapshot_Customer
            FOREIGN KEY (CustomerKey) REFERENCES dw.DimCustomer(CustomerKey),
        CONSTRAINT FK_FactPortfolioDailySnapshot_Account
            FOREIGN KEY (AccountKey) REFERENCES dw.DimAccount(AccountKey),
        CONSTRAINT CK_FactPortfolioDailySnapshot_Values
            CHECK
            (
                InvestedValueEur >= 0
                AND PositionsValueEur >= 0
                AND CashValueEur >= 0
                AND TotalValueEur >= 0
            )
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.FactPortfolioDailySnapshot')
      AND name = 'IX_FactPortfolioDailySnapshot_Customer_Date'
)
    CREATE INDEX IX_FactPortfolioDailySnapshot_Customer_Date
        ON dw.FactPortfolioDailySnapshot(CustomerKey, DateKey)
        INCLUDE (AccountKey, InvestedValueEur, PositionsValueEur, CashValueEur, TotalValueEur);
GO

PRINT N'FactPortfolioDailySnapshot și indexul analitic au fost create cu succes.';
GO
