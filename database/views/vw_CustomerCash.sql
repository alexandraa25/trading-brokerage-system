USE BrokerageDB;
GO

CREATE OR ALTER VIEW core.vw_CustomerCash
AS
SELECT
    c.CustomerId,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    a.AccountNumber,
    ca.CashAccountId,
    ca.Currency,
    ca.AvailableBalance,
    ca.BlockedBalance
FROM core.CashAccount ca
JOIN core.Account a
    ON a.AccountId = ca.AccountId
JOIN core.Customer c
    ON c.CustomerId = a.CustomerId;
GO
