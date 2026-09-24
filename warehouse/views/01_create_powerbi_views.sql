USE BrokerageDW;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Seturi de date pregătite pentru import simplu în Power BI. */
CREATE OR ALTER VIEW dw.vwPowerBiCashFlow
AS
SELECT
    d.FullDate AS Data,
    d.YearNumber AS An,
    d.MonthNumber AS Luna,
    d.YearMonth AS AnLuna,
    customer.CustomerId,
    customer.FullName AS Client,
    account.AccountNumber AS Cont,
    currency.CurrencyCode AS Moneda,
    fact.TransactionType AS TipOperatiune,
    fact.AmountOriginal AS SumaOriginala,
    fact.AmountEur AS SumaEur,
    fact.ExchangeRateToEur AS CursLaEur,
    fact.ExchangeRateSource AS SursaCursului
FROM dw.FactCashTransaction fact
INNER JOIN dw.DimDate d ON d.DateKey=fact.DateKey
INNER JOIN dw.DimCustomer customer ON customer.CustomerKey=fact.CustomerKey
INNER JOIN dw.DimAccount account ON account.AccountKey=fact.AccountKey
INNER JOIN dw.DimCurrency currency ON currency.CurrencyKey=fact.CurrencyKey;
GO

CREATE OR ALTER VIEW dw.vwPowerBiPortfolioEvolution
AS
SELECT
    d.FullDate AS Data,
    d.YearNumber AS An,
    d.MonthNumber AS Luna,
    d.YearMonth AS AnLuna,
    customer.CustomerId,
    customer.FullName AS Client,
    account.AccountNumber AS Cont,
    fact.InvestedValueEur AS ValoareInvestitaEur,
    fact.PositionsValueEur AS ValoarePozitiiEur,
    fact.CashValueEur AS NumerarEur,
    fact.TotalValueEur AS ValoareTotalaEur,
    fact.SourceSystem AS Sursa
FROM dw.FactPortfolioDailySnapshot fact
INNER JOIN dw.DimDate d ON d.DateKey=fact.DateKey
INNER JOIN dw.DimCustomer customer ON customer.CustomerKey=fact.CustomerKey
INNER JOIN dw.DimAccount account ON account.AccountKey=fact.AccountKey;
GO

CREATE OR ALTER VIEW dw.vwPowerBiOrderLifecycle
AS
SELECT
    d.FullDate AS DataCrearii,
    resolved.FullDate AS DataSolutionarii,
    customer.CustomerId,
    customer.FullName AS Client,
    account.AccountNumber AS Cont,
    instrument.Symbol,
    instrument.InstrumentType AS TipInstrument,
    fact.Side AS Sens,
    fact.OrderType AS TipOrdin,
    fact.OrderStatus AS Stare,
    fact.OrderedQuantity AS CantitateCeruta,
    fact.ExecutedQuantity AS CantitateExecutata,
    fact.RemainingQuantity AS CantitateRamasa,
    fact.ExecutionCount AS NumarExecutii,
    fact.ResolutionMinutes AS MinutePanaLaSolutionare,
    fact.RejectionReason AS MotivRespingere
FROM dw.FactOrderLifecycle fact
INNER JOIN dw.DimDate d ON d.DateKey=fact.CreatedDateKey
LEFT JOIN dw.DimDate resolved ON resolved.DateKey=fact.ResolutionDateKey
INNER JOIN dw.DimCustomer customer ON customer.CustomerKey=fact.CustomerKey
INNER JOIN dw.DimAccount account ON account.AccountKey=fact.AccountKey
INNER JOIN dw.DimInstrument instrument ON instrument.InstrumentKey=fact.InstrumentKey;
GO

PRINT N'Vizualizările Power BI au fost create cu succes.';
GO
