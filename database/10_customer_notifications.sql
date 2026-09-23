/* Notificări persistente pentru client. */
IF OBJECT_ID('core.CustomerNotification', 'U') IS NULL
BEGIN
    CREATE TABLE core.CustomerNotification
    (
        CustomerNotificationId BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_CustomerNotification PRIMARY KEY,
        CustomerId BIGINT NOT NULL
            CONSTRAINT FK_CustomerNotification_Customer
            FOREIGN KEY REFERENCES core.Customer(CustomerId),
        NotificationType VARCHAR(40) NOT NULL,
        Title VARCHAR(160) NOT NULL,
        Message VARCHAR(500) NOT NULL,
        IsRead BIT NOT NULL CONSTRAINT DF_CustomerNotification_IsRead DEFAULT (0),
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_CustomerNotification_CreatedAt DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_CustomerNotification_Customer_CreatedAt
        ON core.CustomerNotification(CustomerId, CreatedAt DESC);
END;
GO

INSERT INTO core.CustomerNotification (CustomerId, NotificationType, Title, Message)
SELECT customer.CustomerId, 'Welcome', 'Bun venit în Brokerage',
       'Aici vei primi actualizări despre depuneri, retrageri, verificarea KYC și ordine executate.'
FROM core.Customer customer
WHERE NOT EXISTS
(
    SELECT 1 FROM core.CustomerNotification notification
    WHERE notification.CustomerId = customer.CustomerId
      AND notification.NotificationType = 'Welcome'
);
GO
