IF OBJECT_ID('audit.AccountAdministrationLog', 'U') IS NULL
BEGIN
    CREATE TABLE audit.AccountAdministrationLog
    (
        AccountAdministrationLogId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccountAdministrationLog PRIMARY KEY,
        AccountId BIGINT NOT NULL,
        PreviousStatus VARCHAR(20) NOT NULL,
        NewStatus VARCHAR(20) NOT NULL,
        Reason VARCHAR(500) NOT NULL,
        ChangedBy VARCHAR(255) NOT NULL,
        ChangedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AccountAdministrationLog_ChangedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO
