USE BrokerageDB;
GO

-- Customers
SELECT COUNT(*) AS CustomerCount
FROM core.Customer;
GO

-- KYC
SELECT
    Status,
    COUNT(*) AS CustomerCount
FROM core.KYC
GROUP BY Status;
GO

-- Accounts
SELECT
    Status,
    COUNT(*) AS AccountCount
FROM core.Account
GROUP BY Status;
GO

-- Instruments
SELECT
    InstrumentId,
    Symbol,
    InstrumentName,
    Currency
FROM trading.Instrument
ORDER BY InstrumentId;
GO

-- Contul de numerars
SELECT
    CashAccountId,
    AccountId,
    Currency,
    AvailableBalance,
    BlockedBalance
FROM core.CashAccount
ORDER BY CashAccountId;
GO

-- Orders
SELECT
    Status,
    COUNT(*) AS OrderCount
FROM trading.[Order]
GROUP BY Status;
GO

-- Executions
SELECT COUNT(*) AS ExecutionCount
FROM trading.Execution;
GO

-- Positions
SELECT
    AccountId,
    InstrumentId,
    Quantity,
    AveragePrice
FROM trading.Position;
GO
