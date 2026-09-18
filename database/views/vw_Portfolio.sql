USE BrokerageDB;
GO

CREATE OR ALTER VIEW trading.vw_Portfolio
AS
SELECT
    p.PositionId,
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    a.AccountNumber,
    i.Symbol,
    i.InstrumentName,
    p.Quantity,
    p.AveragePrice,
    p.UpdatedAt
FROM trading.Position p
JOIN core.Account a
    ON a.AccountId = p.AccountId
JOIN core.Customer c
    ON c.CustomerId = a.CustomerId
JOIN trading.Instrument i
    ON i.InstrumentId = p.InstrumentId;
GO
