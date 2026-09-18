USE BrokerageDW;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   DW #6 - Indecși analitici
   ============================================================ */


/* ============================================================
   FactTrade - Analiză după dată

   Permite:
       volumul tranzacționat după dată
       rapoarte lunare
       analiză de serie temporală
   ============================================================ */

CREATE INDEX IX_FactTrade_DateKey
ON dw.FactTrade(DateKey)
INCLUDE
(
    InstrumentKey,
    CustomerKey,
    ExecutedQuantity,
    ExecutionPrice,
    CommissionAmount,
    TradeValueReporting,
    CommissionReporting
);
GO


/* ============================================================
   FactTrade - Analiză după instrument

   Permite:
       volum după instrument
       instrumentele cele mai tranzacționate
       analiză după piață
   ============================================================ */

CREATE INDEX IX_FactTrade_InstrumentKey_DateKey
ON dw.FactTrade
(
    InstrumentKey,
    DateKey
)
INCLUDE
(
    Side,
    ExecutedQuantity,
    ExecutionPrice,
    CommissionAmount,
    TradeValueReporting,
    CommissionReporting
);
GO


/* ============================================================
   FactTrade - Analiză după client

   Permite:
       activitatea de tranzacționare a clientului
       volumul clientului
   ============================================================ */

CREATE INDEX IX_FactTrade_CustomerKey_DateKey
ON dw.FactTrade
(
    CustomerKey,
    DateKey
)
INCLUDE
(
    InstrumentKey,
    Side,
    ExecutedQuantity,
    ExecutionPrice,
    CommissionAmount,
    TradeValueReporting,
    CommissionReporting
);
GO


/* ============================================================
   FactTrade - Analiză după cont
   ============================================================ */

CREATE INDEX IX_FactTrade_AccountKey_DateKey
ON dw.FactTrade
(
    AccountKey,
    DateKey
)
INCLUDE
(
    InstrumentKey,
    ExecutedQuantity,
    ExecutionPrice,
    CommissionAmount,
    TradeValueReporting,
    CommissionReporting
);
GO


PRINT N'Indecșii analitici au fost creați cu succes.';
GO


SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes AS i
INNER JOIN sys.tables AS t
    ON t.object_id = i.object_id
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE s.name = 'dw'
  AND t.name = 'FactTrade'
  AND i.name IS NOT NULL
ORDER BY i.index_id;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    d.YearNumber,
    d.MonthNumber,
    d.MonthName,
    i.Symbol,

    COUNT(*) AS TradeCount,

    SUM(f.ExecutedQuantity) AS TotalQuantity,

    SUM(f.TradeValueReporting) AS TradingVolumeEUR,

    SUM(f.CommissionReporting) AS CommissionRevenueEUR

FROM dw.FactTrade AS f

INNER JOIN dw.DimDate AS d
    ON d.DateKey = f.DateKey

INNER JOIN dw.DimInstrument AS i
    ON i.InstrumentKey = f.InstrumentKey

GROUP BY
    d.YearNumber,
    d.MonthNumber,
    d.MonthName,
    i.Symbol

ORDER BY
    d.YearNumber,
    d.MonthNumber,
    TradingVolumeEUR DESC;



    SELECT
    COUNT(*) AS TradeCount,
    SUM(TradeValueReporting) AS TotalTradingVolumeEUR,
    SUM(CommissionReporting) AS TotalCommissionEUR,
    SUM(ExecutedQuantity) AS TotalQuantity
FROM dw.FactTrade;
