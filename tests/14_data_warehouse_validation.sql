USE BrokerageDW;
GO

/* ============================================================
   Test #14 - Date Warehouse Validare

   Tests:
       1. Dimension counts
       2. Fact/sursă reconciliere
       3. Duplicat business chei
       4. Duplicat fapte
       5. Orfan dimension chei
       6. Measure validare
       7. Date validare
   ============================================================ */

SET NOCOUNT ON;


/* ============================================================
   TEST 1 - Dimensiuni conțin date
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM dw.DimDate)
    THROW 53001, N'TEST EȘUAT: DimDate este gol.', 1;

IF NOT EXISTS (SELECT 1 FROM dw.DimCustomer)
    THROW 53002, N'TEST EȘUAT: DimCustomer este gol.', 1;

IF NOT EXISTS (SELECT 1 FROM dw.DimAccount)
    THROW 53003, N'TEST EȘUAT: DimAccount este gol.', 1;

IF NOT EXISTS (SELECT 1 FROM dw.DimInstrument)
    THROW 53004, N'TEST EȘUAT: DimInstrument este gol.', 1;

PRINT N'REUȘIT - dimensiunile conțin date.';


/* ============================================================
   TEST 2 - Sursă executions vs FactTrade
   ============================================================ */

DECLARE @ExecutionCount BIGINT;
DECLARE @FactCount BIGINT;

SELECT
    @ExecutionCount = COUNT(*)
FROM BrokerageDB.staging.Execution;

SELECT
    @FactCount = COUNT(*)
FROM dw.FactTrade;


SELECT
    @ExecutionCount AS StagingExecutions,
    @FactCount AS FactTrades;


IF @ExecutionCount <> @FactCount
    THROW 53005,
          N'TEST EȘUAT: Execution and FactTrade counts differ.',
          1;

PRINT N'REUȘIT - numărul execuțiilor corespunde cu FactTrade.';


/* ============================================================
   TEST 3 - Chei business Customer duplicate
   ============================================================ */

IF EXISTS
(
    SELECT CustomerId
    FROM dw.DimCustomer
    GROUP BY CustomerId
    HAVING COUNT(*) > 1
)
    THROW 53006,
          N'TEST EȘUAT: Duplicate CustomerId in DimCustomer.',
          1;

PRINT N'REUȘIT - nu există clienți duplicați.';


/* ============================================================
   TEST 4 - Chei business Account duplicate
   ============================================================ */

IF EXISTS
(
    SELECT AccountId
    FROM dw.DimAccount
    GROUP BY AccountId
    HAVING COUNT(*) > 1
)
    THROW 53007,
          N'TEST EȘUAT: Duplicate AccountId in DimAccount.',
          1;

PRINT N'REUȘIT - nu există conturi duplicate.';


/* ============================================================
   TEST 5 - Chei business Instrument duplicate
   ============================================================ */

IF EXISTS
(
    SELECT InstrumentId
    FROM dw.DimInstrument
    GROUP BY InstrumentId
    HAVING COUNT(*) > 1
)
    THROW 53008,
          N'TEST EȘUAT: Duplicate InstrumentId in DimInstrument.',
          1;

PRINT N'REUȘIT - nu există instrumente duplicate.';


/* ============================================================
   TEST 6 - Duplicat executions in FactTrade
   ============================================================ */

IF EXISTS
(
    SELECT ExecutionId
    FROM dw.FactTrade
    GROUP BY ExecutionId
    HAVING COUNT(*) > 1
)
    THROW 53009,
          N'TEST EȘUAT: Duplicate ExecutionId in FactTrade.',
          1;

PRINT N'REUȘIT - nu există fapte duplicate.';


/* ============================================================
   TEST 7 - Orfan CustomerKey
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade AS f
    LEFT JOIN dw.DimCustomer AS c
        ON c.CustomerKey = f.CustomerKey
    WHERE c.CustomerKey IS NULL
)
    THROW 53010,
          N'TEST EȘUAT: Orphan CustomerKey.',
          1;


/* ============================================================
   TEST 8 - Orfan AccountKey
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade AS f
    LEFT JOIN dw.DimAccount AS a
        ON a.AccountKey = f.AccountKey
    WHERE a.AccountKey IS NULL
)
    THROW 53011,
          N'TEST EȘUAT: Orphan AccountKey.',
          1;


/* ============================================================
   TEST 9 - Orfan InstrumentKey
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade AS f
    LEFT JOIN dw.DimInstrument AS i
        ON i.InstrumentKey = f.InstrumentKey
    WHERE i.InstrumentKey IS NULL
)
    THROW 53012,
          N'TEST EȘUAT: Orphan InstrumentKey.',
          1;


/* ============================================================
   TEST 10 - Orfan DateKey
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade AS f
    LEFT JOIN dw.DimDate AS d
        ON d.DateKey = f.DateKey
    WHERE d.DateKey IS NULL
)
    THROW 53013,
          N'TEST EȘUAT: Orphan DateKey.',
          1;

PRINT N'REUȘIT - nu există chei de dimensiune orfane.';


/* ============================================================
   TEST 11 - Trade măsuri
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade
    WHERE ExecutedQuantity <= 0
       OR ExecutionPrice <= 0
       OR TradeValue <= 0
       OR CommissionAmount < 0
)
    THROW 53014,
          N'TEST EȘUAT: Invalid FactTrade measure.',
          1;

PRINT N'REUȘIT - măsurile faptelor sunt valide.';


/* ============================================================
   TEST 12 - DateKey corespunde to ExecutedAt
   ============================================================ */

IF EXISTS
(
    SELECT 1
    FROM dw.FactTrade
    WHERE DateKey <>
          CONVERT
          (
              INT,
              CONVERT
              (
                  CHAR(8),
                  CAST(ExecutedAt AS DATE),
                  112
              )
          )
)
    THROW 53015,
          N'TEST EȘUAT: Invalid DateKey.',
          1;

PRINT N'REUȘIT - cheile de dată sunt valide.';


/* ============================================================
   Rezultat final
   ============================================================ */

PRINT N'============================================';
PRINT N'TESTUL #14 A TRECUT';
PRINT N'Validarea depozitului de date a reușit.';
PRINT N'============================================';
GO



