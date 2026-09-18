USE BrokerageDB;
GO

/*
===========================================================
TEST 09 - EXECUȚIE PARȚIALĂ + MEDIE PONDERATĂ
===========================================================

Scop:
- Verifică execuția parțială a ordinului
- Verifică execuțiile multiple ale aceluiași ordin
- Verifică Pending -> PartiallyExecuted -> Executed
- Verifică ponderată medie execuție preț
- Verifică poziția și prețul mediu
- Verifică retragerea numerarului și comisionul

Așteptat executions:
    30 @ 150
    40 @ 149
    30 @ 148

Rezultat așteptat:
    Total cantitate      = 100
    Valoare totală tranzacționată   = 14,900
    Ponderată avg preț  = 149
    Comision          = 37.25
    Impact total asupra numerarului   = 14,937.25
===========================================================
*/


/* =========================================================
   1. CREEAZĂ ORDINUL DE TEST
   ========================================================= */

INSERT INTO trading.[Order]
(
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status
)
VALUES
(
    6,
    1,
    'BUY',
    'LIMIT',
    100,
    160,
    'Pending'
);

DECLARE @OrderId BIGINT = SCOPE_IDENTITY();

SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status
FROM trading.[Order]
WHERE OrderId = @OrderId;


/* =========================================================
   2. PRIMA EXECUȚIE PARȚIALĂ
      30 @ 150
   ========================================================= */

EXEC trading.usp_ExecuteOrder
    @OrderId = @OrderId,
    @ExecutedQuantity = 30,
    @ExecutionPrice = 150;


/* Rezultat așteptat:
   Stare = PartiallyExecuted
   Executed = 30
*/


SELECT
    OrderId,
    Status,
    Quantity
FROM trading.[Order]
WHERE OrderId = @OrderId;

SELECT
    ExecutionId,
    OrderId,
    ExecutedQuantity,
    ExecutionPrice
FROM trading.Execution
WHERE OrderId = @OrderId
ORDER BY ExecutionId;


/* =========================================================
   3. A DOUA EXECUȚIE PARȚIALĂ
      40 @ 149
   ========================================================= */

EXEC trading.usp_ExecuteOrder
    @OrderId = @OrderId,
    @ExecutedQuantity = 40,
    @ExecutionPrice = 149;


/* Rezultat așteptat:
   Stare = PartiallyExecuted
   Executed = 70
*/


SELECT
    OrderId,
    Status,
    Quantity
FROM trading.[Order]
WHERE OrderId = @OrderId;


/* =========================================================
   4. EXECUȚIA FINALĂ
      30 @ 148
   ========================================================= */

EXEC trading.usp_ExecuteOrder
    @OrderId = @OrderId,
    @ExecutedQuantity = 30,
    @ExecutionPrice = 148;


/* Rezultat așteptat:
   Stare = Executed
   Executed = 100
*/


SELECT
    OrderId,
    Status,
    Quantity
FROM trading.[Order]
WHERE OrderId = @OrderId;


/* =========================================================
   5. VERIFICĂ EXECUȚIILE
   ========================================================= */

SELECT
    ExecutionId,
    OrderId,
    ExecutedQuantity,
    ExecutionPrice,
    ExecutedQuantity * ExecutionPrice AS TradeValue,
    ExecutedAt
FROM trading.Execution
WHERE OrderId = @OrderId
ORDER BY ExecutionId;


/* Rezultat așteptat:

30 * 150 = 4,500
40 * 149 = 5,960
30 * 148 = 4,440

Total = 14,900
*/


/* =========================================================
   6. VERIFICĂ MEDIA PONDERATĂ
   ========================================================= */

SELECT
    OrderId,
    SUM(ExecutedQuantity) AS TotalExecutedQuantity,
    SUM(ExecutedQuantity * ExecutionPrice) AS TotalTradeValue,
    SUM(ExecutedQuantity * ExecutionPrice)
        / NULLIF(SUM(ExecutedQuantity), 0)
        AS WeightedAverageExecutionPrice
FROM trading.Execution
WHERE OrderId = @OrderId
GROUP BY OrderId;


/* Rezultat așteptat:

TotalExecutedQuantity       = 100
TotalTradeValue             = 14,900
WeightedAveragePrice        = 149
*/


/* =========================================================
   7. VERIFICĂ POZIȚIA
   ========================================================= */

SELECT
    PositionId,
    AccountId,
    InstrumentId,
    Quantity,
    AveragePrice
FROM trading.Position
WHERE AccountId = 6
  AND InstrumentId = 1;


/* Rezultat așteptat:

Cantitate     = 100
AveragePrice = 149
*/


/* =========================================================
   8. VERIFICĂ TRANZACȚIILE DE NUMERAR
   ========================================================= */

SELECT
    CashTransactionId,
    CashAccountId,
    TransactionType,
    Amount,
    Currency,
    ReferenceType,
    ReferenceId,
    Description,
    CreatedAt
FROM trading.CashTransaction
WHERE ReferenceId = @OrderId
ORDER BY CashTransactionId;


/* Rezultat așteptat:

Trade       = -14,900
Comision  = -37.25
*/


/* =========================================================
   9. VALIDAREA FINALĂ
   ========================================================= */

SELECT
    o.OrderId,
    o.Status AS OrderStatus,
    o.Quantity AS OrderQuantity,

    SUM(e.ExecutedQuantity) AS ExecutedQuantity,

    SUM(e.ExecutedQuantity * e.ExecutionPrice)
        / NULLIF(SUM(e.ExecutedQuantity), 0)
        AS WeightedAverageExecutionPrice,

    p.Quantity AS PositionQuantity,
    p.AveragePrice AS PositionAveragePrice

FROM trading.[Order] o

LEFT JOIN trading.Execution e
    ON e.OrderId = o.OrderId

LEFT JOIN trading.Position p
    ON p.AccountId = o.AccountId
   AND p.InstrumentId = o.InstrumentId

WHERE o.OrderId = @OrderId

GROUP BY
    o.OrderId,
    o.Status,
    o.Quantity,
    p.Quantity,
    p.AveragePrice;


/*
===========================================================
REZULTAT FINAL AȘTEPTAT

OrderStatus                   = Executed
OrderQuantity                 = 100
ExecutedQuantity              = 100
WeightedAverageExecutionPrice = 149
PositionQuantity              = 100
PositionAveragePrice          = 149

TESTUL 09 A TRECUT
===========================================================
*/
