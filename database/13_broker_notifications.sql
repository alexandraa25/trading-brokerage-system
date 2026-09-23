/* Notificări persistente, comune pentru echipa de brokeri. */
IF OBJECT_ID('audit.BrokerNotification', 'U') IS NULL
BEGIN
    CREATE TABLE audit.BrokerNotification
    (
        BrokerNotificationId BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_BrokerNotification PRIMARY KEY,
        NotificationType VARCHAR(40) NOT NULL,
        Title VARCHAR(160) NOT NULL,
        Message VARCHAR(500) NOT NULL,
        IsRead BIT NOT NULL CONSTRAINT DF_BrokerNotification_IsRead DEFAULT (0),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_BrokerNotification_CreatedAt DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_BrokerNotification_CreatedAt
        ON audit.BrokerNotification(CreatedAt DESC);
END;
GO

IF NOT EXISTS (SELECT 1 FROM audit.BrokerNotification WHERE NotificationType = 'Welcome')
    INSERT INTO audit.BrokerNotification (NotificationType, Title, Message)
    VALUES ('Welcome', 'Centrul broker este activ',
            'Aici vei primi ordine noi, confirmări de execuție și motivele pentru execuțiile blocate.');
GO
