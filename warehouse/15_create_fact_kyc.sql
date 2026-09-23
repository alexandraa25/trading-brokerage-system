USE BrokerageDW;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* DW #15 - un rând pentru fiecare dosar KYC. */
IF OBJECT_ID('dw.FactKyc', 'U') IS NULL
BEGIN
    CREATE TABLE dw.FactKyc
    (
        KycKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SubmittedDateKey INT NOT NULL REFERENCES dw.DimDate(DateKey),
        ResolvedDateKey INT NULL REFERENCES dw.DimDate(DateKey),
        CustomerKey INT NOT NULL REFERENCES dw.DimCustomer(CustomerKey),
        KycId BIGINT NOT NULL UNIQUE,
        KycStatus VARCHAR(20) NOT NULL,
        DocumentType VARCHAR(50) NULL,
        SubmittedAt DATETIME2(3) NOT NULL,
        ResolvedAt DATETIME2(3) NULL,
        ResolvedBy VARCHAR(100) NULL,
        ResolutionDays INT NULL,
        RejectionReason VARCHAR(500) NULL,
        DWCreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_FactKyc_Resolution CHECK (ResolutionDays IS NULL OR ResolutionDays >= 0)
    );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dw.FactKyc') AND name='IX_FactKyc_Status_SubmittedDate')
    CREATE INDEX IX_FactKyc_Status_SubmittedDate ON dw.FactKyc(KycStatus, SubmittedDateKey)
    INCLUDE(CustomerKey, ResolutionDays);
GO
