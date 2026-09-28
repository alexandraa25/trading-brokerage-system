USE BrokerageDB;
GO

/* Copie de analiză pentru acțiunile administrative, de ordine și conectări. */
IF OBJECT_ID('staging.ApplicationUser', 'U') IS NULL
    CREATE TABLE staging.ApplicationUser
    (
        ApiUserId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        CustomerId BIGINT NULL,
        Email VARCHAR(255) NOT NULL,
        UserRole VARCHAR(30) NOT NULL,
        IsActive BIT NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL,
        UpdatedAt DATETIME2(3) NOT NULL,
        ExtractedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
    );
GO
IF OBJECT_ID('staging.OperationalAudit', 'U') IS NULL
    CREATE TABLE staging.OperationalAudit
    (
        SourceType VARCHAR(20) NOT NULL,
        SourceAuditId BIGINT NOT NULL,
        ApiUserId UNIQUEIDENTIFIER NULL,
        ChangedBy VARCHAR(320) NULL,
        Activity VARCHAR(50) NOT NULL,
        RelatedOrderId BIGINT NULL,
        Details VARCHAR(1000) NULL,
        OccurredAt DATETIME2(3) NOT NULL,
        ExtractedAt DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_StagingOperationalAudit PRIMARY KEY (SourceType, SourceAuditId)
    );
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    TRUNCATE TABLE staging.OperationalAudit;
    TRUNCATE TABLE staging.ApplicationUser;

    INSERT INTO staging.ApplicationUser
        (ApiUserId, CustomerId, Email, UserRole, IsActive, CreatedAt, UpdatedAt)
    SELECT ApiUserId, CustomerId, Email, Role, IsActive, CreatedAt, UpdatedAt
    FROM security.ApiUser;

    INSERT INTO staging.OperationalAudit
        (SourceType, SourceAuditId, ApiUserId, ChangedBy, Activity, RelatedOrderId, Details, OccurredAt)
    SELECT 'Session', UserSessionHistoryId, ApiUserId, NULL, 'Login', NULL, NULL, LoggedInAt
    FROM audit.UserSessionHistory
    UNION ALL
    SELECT 'Access', AccessAuditLogId, ApiUserId, ChangedBy, Action, NULL, Details, ChangedAt
    FROM audit.AccessAuditLog
    UNION ALL
    SELECT 'Order', OrderActivityLogId, NULL, ChangedBy, Activity, OrderId, Details, ChangedAt
    FROM audit.OrderActivityLog;

    COMMIT TRANSACTION;
    PRINT N'Jurnalul operațional a fost reîmprospătat în staging.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
