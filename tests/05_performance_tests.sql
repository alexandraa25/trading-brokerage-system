USE BrokerageDB;
GO

SET NOCOUNT ON;

;WITH Numbers AS
(
    SELECT TOP (100000)
        ROW_NUMBER() OVER
        (
            ORDER BY (SELECT NULL)
        ) AS N
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO trading.[Order]
(
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt,
    UpdatedAt
)
SELECT
    6 AS AccountId,
    ((N - 1) % 5) + 1 AS InstrumentId,

    CASE
        WHEN N % 2 = 0 THEN 'BUY'
        ELSE 'SELL'
    END,

    CASE
        WHEN N % 3 = 0 THEN 'MARKET'
        ELSE 'LIMIT'
    END,

    CAST(((N % 100) + 1) * 10 AS DECIMAL(19,8)),

    CASE
        WHEN N % 3 = 0 THEN NULL
        ELSE CAST(100 + (N % 100) AS DECIMAL(19,8))
    END,

    CASE
        WHEN N % 10 IN (0,1,2,3,4,5,6)
            THEN 'Pending'

        WHEN N % 10 IN (7,8)
            THEN 'Cancelled'

        ELSE 'Rejected'
    END,

    DATEADD(SECOND, -N, SYSUTCDATETIME()),
    DATEADD(SECOND, -N, SYSUTCDATETIME())

FROM Numbers;
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt
FROM trading.[Order]
WHERE AccountId = 6
ORDER BY CreatedAt DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt
FROM trading.[Order]
WHERE AccountId = 6
  AND Status = 'Pending'
ORDER BY CreatedAt DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT
    o.OrderId,
    o.AccountId,
    i.Symbol,
    o.Side,
    o.OrderType,
    o.Quantity,
    o.LimitPrice,
    o.Status,
    o.CreatedAt
FROM trading.[Order] o
JOIN trading.Instrument i
    ON i.InstrumentId = o.InstrumentId
WHERE o.InstrumentId = 1
  AND o.Status = 'Pending'
ORDER BY o.CreatedAt DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt
FROM trading.[Order]
WHERE Status = 'Pending'
ORDER BY CreatedAt DESC;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

