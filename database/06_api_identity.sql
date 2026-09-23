USE BrokerageDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'security')
    EXEC('CREATE SCHEMA security');
GO

IF OBJECT_ID('security.ApiUser', 'U') IS NULL
BEGIN
    CREATE TABLE security.ApiUser
    (
        ApiUserId    UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DF_ApiUser_Id DEFAULT NEWID(),
        CustomerId   BIGINT NULL,
        Email        VARCHAR(255) NOT NULL,
        PasswordHash NVARCHAR(500) NOT NULL,
        Role         VARCHAR(30) NOT NULL,
        IsActive     BIT NOT NULL
            CONSTRAINT DF_ApiUser_IsActive DEFAULT (1),
        CreatedAt    DATETIME2(3) NOT NULL
            CONSTRAINT DF_ApiUser_CreatedAt DEFAULT SYSUTCDATETIME(),
        UpdatedAt    DATETIME2(3) NOT NULL
            CONSTRAINT DF_ApiUser_UpdatedAt DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_ApiUser PRIMARY KEY (ApiUserId),
        CONSTRAINT UQ_ApiUser_Email UNIQUE (Email),
        CONSTRAINT FK_ApiUser_Customer FOREIGN KEY (CustomerId)
            REFERENCES core.Customer(CustomerId),
        CONSTRAINT CK_ApiUser_Role CHECK
            (Role IN ('Customer', 'Broker', 'ComplianceOfficer', 'Administrator'))
    );

    CREATE INDEX IX_ApiUser_CustomerId
        ON security.ApiUser(CustomerId)
        WHERE CustomerId IS NOT NULL;
END;
GO

PRINT N'Identitățile locale pentru API au fost pregătite.';
GO
