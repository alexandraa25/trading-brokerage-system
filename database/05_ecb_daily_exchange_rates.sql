USE BrokerageDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

/* Jurnalul importurilor automate de cursuri oficiale BCE. */
IF OBJECT_ID('audit.ExchangeRateImportLog', 'U') IS NULL
BEGIN
    CREATE TABLE audit.ExchangeRateImportLog
    (
        ImportRunId BIGINT IDENTITY(1,1) NOT NULL,
        SourceSystem VARCHAR(50) NOT NULL,
        DateFrom DATE NOT NULL,
        DateTo DATE NOT NULL,
        StartedAt DATETIME2(3) NOT NULL
            CONSTRAINT DF_ExchangeRateImportLog_StartedAt DEFAULT SYSUTCDATETIME(),
        CompletedAt DATETIME2(3) NULL,
        Status VARCHAR(20) NOT NULL,
        RowsReceived INT NOT NULL
            CONSTRAINT DF_ExchangeRateImportLog_RowsReceived DEFAULT (0),
        RowsInserted INT NOT NULL
            CONSTRAINT DF_ExchangeRateImportLog_RowsInserted DEFAULT (0),
        RowsUpdated INT NOT NULL
            CONSTRAINT DF_ExchangeRateImportLog_RowsUpdated DEFAULT (0),
        ErrorMessage NVARCHAR(2000) NULL,

        CONSTRAINT PK_ExchangeRateImportLog PRIMARY KEY (ImportRunId),
        CONSTRAINT CK_ExchangeRateImportLog_Status
            CHECK (Status IN ('Running', 'Succeeded', 'Failed'))
    );
END;
GO

IF COL_LENGTH('trading.Execution', 'ExchangeRateSource') IS NULL
    ALTER TABLE trading.Execution ADD ExchangeRateSource VARCHAR(50) NULL;
GO

UPDATE trading.Execution
SET ExchangeRateSource =
    CASE WHEN TradeCurrency = ReportingCurrency
         THEN 'IDENTITY'
         ELSE 'DEMO_EUR_DAILY'
    END
WHERE ExchangeRateSource IS NULL;
GO

ALTER TABLE trading.Execution
    ALTER COLUMN ExchangeRateSource VARCHAR(50) NOT NULL;
GO

PRINT N'Importul zilnic al cursurilor BCE a fost pregătit.';
GO

