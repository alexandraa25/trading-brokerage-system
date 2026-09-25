USE BrokerageDB;
GO

IF OBJECT_ID('core.CustomerWatchlist', 'U') IS NULL
CREATE TABLE core.CustomerWatchlist
(
    CustomerWatchlistId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CustomerWatchlist PRIMARY KEY,
    CustomerId BIGINT NOT NULL CONSTRAINT FK_CustomerWatchlist_Customer REFERENCES core.Customer(CustomerId),
    InstrumentId BIGINT NOT NULL CONSTRAINT FK_CustomerWatchlist_Instrument REFERENCES trading.Instrument(InstrumentId),
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_CustomerWatchlist_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_CustomerWatchlist UNIQUE(CustomerId, InstrumentId)
);
GO

IF OBJECT_ID('core.CustomerPriceAlert', 'U') IS NULL
CREATE TABLE core.CustomerPriceAlert
(
    CustomerPriceAlertId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CustomerPriceAlert PRIMARY KEY,
    CustomerId BIGINT NOT NULL CONSTRAINT FK_CustomerPriceAlert_Customer REFERENCES core.Customer(CustomerId),
    InstrumentId BIGINT NOT NULL CONSTRAINT FK_CustomerPriceAlert_Instrument REFERENCES trading.Instrument(InstrumentId),
    Direction VARCHAR(10) NOT NULL CONSTRAINT CK_CustomerPriceAlert_Direction CHECK(Direction IN ('Above','Below')),
    TargetPrice DECIMAL(19,8) NOT NULL CONSTRAINT CK_CustomerPriceAlert_Target CHECK(TargetPrice > 0),
    IsActive BIT NOT NULL CONSTRAINT DF_CustomerPriceAlert_IsActive DEFAULT(1),
    TriggeredAt DATETIME2(3) NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_CustomerPriceAlert_CreatedAt DEFAULT SYSUTCDATETIME()
);
GO

CREATE OR ALTER PROCEDURE core.usp_CheckCustomerPriceAlerts
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH LatestQuotes AS
    (
        SELECT InstrumentId, MarketPrice, ROW_NUMBER() OVER(PARTITION BY InstrumentId ORDER BY QuoteDate DESC) AS SequenceNumber
        FROM trading.MarketQuote
    )
    UPDATE alert SET IsActive = 0, TriggeredAt = SYSUTCDATETIME()
    FROM core.CustomerPriceAlert alert
    INNER JOIN LatestQuotes quote ON quote.InstrumentId = alert.InstrumentId AND quote.SequenceNumber = 1
    WHERE alert.IsActive = 1 AND ((alert.Direction = 'Above' AND quote.MarketPrice >= alert.TargetPrice) OR (alert.Direction = 'Below' AND quote.MarketPrice <= alert.TargetPrice));
END;
GO
