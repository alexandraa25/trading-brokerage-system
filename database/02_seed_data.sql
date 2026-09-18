USE BrokerageDB;
GO

-- =============================================
-- Tipuri de clienți
-- =============================================

INSERT INTO core.CustomerType
(
    TypeCode,
    TypeName,
    Description
)
VALUES
('INDIVIDUAL', 'Individual Customer', 'Individual retail customer'),
('CORPORATE', 'Corporate Customer', 'Corporate customer'),
('INSTITUTIONAL', 'Institutional Customer', 'Institutional customer');
GO


INSERT INTO core.Customer
(
    CustomerTypeId,
    FirstName,
    LastName,
    Email,
    Phone,
    DateOfBirth,
    Status
)
VALUES
(
    1,
    'Alex',
    'Popescu',
    'alex.popescu@example.test',
    '0700000001',
    '1995-05-10',
    'Active'
),
(
    1,
    'Maria',
    'Ionescu',
    'maria.ionescu@example.test',
    '0700000002',
    '1994-08-15',
    'Active'
),
(
    1,
    'Andrei',
    'Marin',
    'andrei.marin@example.test',
    '0700000003',
    '1993-02-20',
    'Active'
),
(
    1,
    'Elena',
    'Dumitru',
    'elena.dumitru@example.test',
    '0700000004',
    '1996-11-12',
    'Active'
),
(
    1,
    'Victor',
    'Stan',
    'victor.stan@example.test',
    '0700000005',
    '1992-07-25',
    'Active'
);
GO


INSERT INTO core.KYC
(
    CustomerId,
    Status,
    DocumentType,
    VerifiedAt,
    VerifiedBy
)
SELECT
    CustomerId,
    'Approved',
    'IdentityCard',
    SYSUTCDATETIME(),
    'system'
FROM core.Customer;
GO


INSERT INTO core.Account
(
    CustomerId,
    AccountNumber,
    Currency,
    Status
)
VALUES
(1, 'ACC-000001', 'EUR', 'Active'),
(2, 'ACC-000002', 'EUR', 'Active'),
(3, 'ACC-000003', 'EUR', 'Active'),
(4, 'ACC-000004', 'EUR', 'Active'),
(5, 'ACC-000005', 'EUR', 'Active');
GO



INSERT INTO trading.Market
(
    MarketCode,
    MarketName,
    CountryCode,
    Currency
)
VALUES
('XNAS', 'NASDAQ', 'US', 'USD'),
('XNYS', 'New York Stock Exchange', 'US', 'USD'),
('XLON', 'London Stock Exchange', 'GB', 'GBP');
GO


INSERT INTO trading.Issuer
(
    IssuerCode,
    IssuerName,
    CountryCode
)
VALUES
('ALPHA', 'Alpha Technologies', 'US'),
('BETA', 'Beta Financial', 'US'),
('GAMMA', 'Gamma Energy', 'GB'),
('DELTA', 'Delta Healthcare', 'US'),
('OMEGA', 'Omega Consumer Goods', 'GB');
GO


INSERT INTO trading.Instrument
(
    MarketId,
    IssuerId,
    Symbol,
    InstrumentName,
    InstrumentType,
    Currency
)
VALUES
(1, 1, 'ALPH', 'Alpha Technologies Stock', 'Stock', 'USD'),
(2, 2, 'BETA', 'Beta Financial Stock', 'Stock', 'USD'),
(3, 3, 'GAMM', 'Gamma Energy Stock', 'Stock', 'GBP'),
(2, 4, 'DELT', 'Delta Healthcare Stock', 'Stock', 'USD'),
(3, 5, 'OMGA', 'Omega Consumer Goods', 'Stock', 'GBP');
GO


INSERT INTO core.CashAccount
(
    AccountId,
    Currency,
    AvailableBalance,
    BlockedBalance
)
VALUES
(1, 'EUR', 0, 0),
(2, 'EUR', 0, 0),
(3, 'EUR', 0, 0),
(4, 'EUR', 0, 0),
(5, 'EUR', 0, 0);
GO



