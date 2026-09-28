USE BrokerageDB;
GO

IF COL_LENGTH('security.ApiUser', 'SessionVersion') IS NULL
BEGIN
    ALTER TABLE security.ApiUser ADD SessionVersion INT NOT NULL CONSTRAINT DF_ApiUser_SessionVersion DEFAULT 1;
END
GO
