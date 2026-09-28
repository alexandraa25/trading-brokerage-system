USE BrokerageDW;
GO

/* Dimensiune pentru utilizatorii aplicației și fapt pentru acțiunile auditate. */
IF OBJECT_ID('dw.DimApplicationUser', 'U') IS NULL
    CREATE TABLE dw.DimApplicationUser
    (
        ApplicationUserKey INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ApiUserId UNIQUEIDENTIFIER NOT NULL UNIQUE,
        CustomerId BIGINT NULL,
        Email VARCHAR(255) NOT NULL,
        UserRole VARCHAR(30) NOT NULL,
        IsActive BIT NOT NULL,
        SourceCreatedAt DATETIME2(3) NOT NULL,
        SourceUpdatedAt DATETIME2(3) NOT NULL,
        DWCreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
    );
GO
IF OBJECT_ID('dw.FactOperationalAudit', 'U') IS NULL
    CREATE TABLE dw.FactOperationalAudit
    (
        OperationalAuditKey BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        DateKey INT NOT NULL REFERENCES dw.DimDate(DateKey),
        ApplicationUserKey INT NULL REFERENCES dw.DimApplicationUser(ApplicationUserKey),
        SourceType VARCHAR(20) NOT NULL,
        SourceAuditId BIGINT NOT NULL,
        Activity VARCHAR(50) NOT NULL,
        RelatedOrderId BIGINT NULL,
        Details VARCHAR(1000) NULL,
        OccurredAt DATETIME2(3) NOT NULL,
        DWCreatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        DWUpdatedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_FactOperationalAudit_Source UNIQUE (SourceType, SourceAuditId)
    );
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dw.FactOperationalAudit') AND name='IX_FactOperationalAudit_Date_Action')
    CREATE INDEX IX_FactOperationalAudit_Date_Action
        ON dw.FactOperationalAudit(DateKey, Activity)
        INCLUDE (ApplicationUserKey, SourceType, RelatedOrderId);
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE target
    SET CustomerId=source.CustomerId, Email=source.Email, UserRole=source.UserRole,
        IsActive=source.IsActive, SourceCreatedAt=source.CreatedAt,
        SourceUpdatedAt=source.UpdatedAt, DWUpdatedAt=SYSUTCDATETIME()
    FROM dw.DimApplicationUser target
    INNER JOIN BrokerageDB.staging.ApplicationUser source ON source.ApiUserId=target.ApiUserId;

    INSERT INTO dw.DimApplicationUser
        (ApiUserId, CustomerId, Email, UserRole, IsActive, SourceCreatedAt, SourceUpdatedAt)
    SELECT ApiUserId, CustomerId, Email, UserRole, IsActive, CreatedAt, UpdatedAt
    FROM BrokerageDB.staging.ApplicationUser source
    WHERE NOT EXISTS (SELECT 1 FROM dw.DimApplicationUser target WHERE target.ApiUserId=source.ApiUserId);

    IF OBJECT_ID('tempdb..#SourceOperationalAudit') IS NOT NULL DROP TABLE #SourceOperationalAudit;
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), CAST(a.OccurredAt AS DATE), 112)) AS DateKey,
        COALESCE(byId.ApplicationUserKey, byEmail.ApplicationUserKey) AS ApplicationUserKey,
        a.SourceType, a.SourceAuditId, a.Activity, a.RelatedOrderId, a.Details, a.OccurredAt
    INTO #SourceOperationalAudit
    FROM BrokerageDB.staging.OperationalAudit a
    LEFT JOIN dw.DimApplicationUser byId ON byId.ApiUserId=a.ApiUserId
    LEFT JOIN dw.DimApplicationUser byEmail ON byEmail.Email=a.ChangedBy;

    UPDATE target
    SET DateKey=source.DateKey, ApplicationUserKey=source.ApplicationUserKey,
        Activity=source.Activity, RelatedOrderId=source.RelatedOrderId,
        Details=source.Details, OccurredAt=source.OccurredAt, DWUpdatedAt=SYSUTCDATETIME()
    FROM dw.FactOperationalAudit target
    INNER JOIN #SourceOperationalAudit source
        ON source.SourceType=target.SourceType AND source.SourceAuditId=target.SourceAuditId
    WHERE target.DateKey<>source.DateKey
       OR ISNULL(target.ApplicationUserKey,-1)<>ISNULL(source.ApplicationUserKey,-1)
       OR target.Activity<>source.Activity
       OR ISNULL(target.RelatedOrderId,-1)<>ISNULL(source.RelatedOrderId,-1)
       OR ISNULL(target.Details,'')<>ISNULL(source.Details,'')
       OR target.OccurredAt<>source.OccurredAt;

    INSERT INTO dw.FactOperationalAudit
        (DateKey, ApplicationUserKey, SourceType, SourceAuditId, Activity, RelatedOrderId, Details, OccurredAt)
    SELECT DateKey, ApplicationUserKey, SourceType, SourceAuditId, Activity, RelatedOrderId, Details, OccurredAt
    FROM #SourceOperationalAudit source
    WHERE NOT EXISTS
    (
        SELECT 1 FROM dw.FactOperationalAudit target
        WHERE target.SourceType=source.SourceType AND target.SourceAuditId=source.SourceAuditId
    );

    COMMIT TRANSACTION;
    PRINT N'DimApplicationUser și FactOperationalAudit au fost încărcate.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
