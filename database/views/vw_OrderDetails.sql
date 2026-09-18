USE BrokerageDB;
GO

CREATE OR ALTER VIEW trading.vw_OrderDetails
AS
SELECT
    o.OrderId,
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    a.AccountNumber,
    i.Symbol,
    i.InstrumentName,
    m.MarketCode,
    o.Side,
    o.OrderType,
    o.Quantity,
    o.LimitPrice,
    o.Status,
    o.CreatedAt,
    o.UpdatedAt
FROM trading.[Order] o
JOIN core.Account a
    ON a.AccountId = o.AccountId
JOIN core.Customer c
    ON c.CustomerId = a.CustomerId
JOIN trading.Instrument i
    ON i.InstrumentId = o.InstrumentId
JOIN trading.Market m
    ON m.MarketId = i.MarketId;
GO
