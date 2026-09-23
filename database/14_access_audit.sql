IF OBJECT_ID('audit.AccessAuditLog', 'U') IS NULL
BEGIN
    CREATE TABLE audit.AccessAuditLog
    (
        AccessAuditLogId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AccessAuditLog PRIMARY KEY,
        ApiUserId UNIQUEIDENTIFIER NULL,
        Action VARCHAR(50) NOT NULL,
        TargetEmail VARCHAR(255) NOT NULL,
        Details VARCHAR(500) NULL,
        ChangedBy VARCHAR(255) NOT NULL,
        ChangedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AccessAuditLog_ChangedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO
