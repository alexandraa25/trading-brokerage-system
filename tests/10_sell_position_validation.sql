USE BrokerageDB;
GO

/*
===========================================================
TEST 10 - SELL + VALIDAREA POZIȚIEI
===========================================================

Scop:
- Verifică execuția SELL validă
- Verifică reducerea cantității poziției după SELL
- Verifică încasarea numerarului pentru SELL
- Verifică comisionul pentru SELL
- Verifică insuficient poziție validare
- Verifică revenirea după un SELL invalid
- Verifică validarea prețului SELL LIMIT

Scenario:
Inițial poziție:
    100 ALPH

SELL valid:
    20 @ 150

Poziție așteptată:
    80 ALPH

Valoare așteptată a tranzacției:
    20 * 150 = 3,000

Comision așteptat:
    3,000 * 0.25% = 7.50

Încasare netă așteptată:
    3,000 - 7.50 = 2,992.50
===========================================================
*/


/* =========================================================
   1. VERIFICĂ POZIȚIA INIȚIALĂ
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


/*
Rezultat așteptat înainte de SELL:

Cantitate >= 20
*/


/* =========================================================
   2. CREEAZĂ UN ORDIN SELL VALID
   ========================================================= */

DECLARE @SellOrderId BIGINT;

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
    'SELL',
    'LIMIT',
    20,
    145,
    'Pending'
);

SET @SellOrderId = SCOPE_IDENTITY();


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
WHERE OrderId = @SellOrderId;


/* =========================================================
   3. EXECUTĂ SELL-UL VALID
      20 @ 150
   ========================================================= */

EXEC trading.usp_ExecuteOrder
    @OrderId = @SellOrderId,
    @ExecutedQuantity = 20,
    @ExecutionPrice = 150;


/*
Rezultat așteptat:

Ordin stare = Executed
*/


/* =========================================================
   4. VERIFICĂ ORDINUL
   ========================================================= */

SELECT
    OrderId,
    Side,
    Quantity,
    Status
FROM trading.[Order]
WHERE OrderId = @SellOrderId;


/* =========================================================
   5. VERIFICĂ EXECUȚIA
   ========================================================= */

SELECT
    ExecutionId,
    OrderId,
    ExecutedQuantity,
    ExecutionPrice,
    ExecutedQuantity * ExecutionPrice AS TradeValue
FROM trading.Execution
WHERE OrderId = @SellOrderId;


/*
Rezultat așteptat:

ExecutedQuantity = 20
ExecutionPrice   = 150
TradeValue       = 3000
*/


/* =========================================================
   6. VERIFICĂ POZIȚIA DECREASE
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


/*
Rezultat așteptat după SELL:

Cantitatea poziției a scăzut cu 20.
If inițial cantitate was 100:

Cantitate = 80
*/


/* =========================================================
   7. VERIFICĂ TRANZACȚIILE DE NUMERAR
   ========================================================= */

SELECT
    CashTransactionId,
    TransactionType,
    Amount,
    Currency,
    ReferenceType,
    ReferenceId,
    Description,
    CreatedAt
FROM trading.CashTransaction
WHERE ReferenceId = @SellOrderId
ORDER BY CashTransactionId;


/*
Rezultat așteptat:

Trade       = +3000.00
Comision  = -7.50
*/


/* =========================================================
   8. CREEAZĂ UN SELL INVALID
      Încearcă vânzarea unei cantități mai mari decât poziția disponibilă
   ========================================================= */

DECLARE @InvalidSellOrderId BIGINT;

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
    'SELL',
    'LIMIT',
    81,
    140,
    'Pending'
);

SET @InvalidSellOrderId = SCOPE_IDENTITY();


SELECT
    OrderId,
    Side,
    Quantity,
    LimitPrice,
    Status
FROM trading.[Order]
WHERE OrderId = @InvalidSellOrderId;


/* =========================================================
   9. EXECUTĂ SELL-UL INVALID
      Rezultat așteptat: ERROR
   ========================================================= */

BEGIN TRY

    EXEC trading.usp_ExecuteOrder
        @OrderId = @InvalidSellOrderId,
        @ExecutedQuantity = 81,
        @ExecutionPrice = 150;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


/*
Rezultat așteptat:

Execuția este respinsă deoarece cantitatea poziției
is insuficient.
*/


/* =========================================================
   10. VERIFICĂ FAPTUL CĂ ORDINUL INVALID NU A FOST EXECUTAT
   ========================================================= */

SELECT
    OrderId,
    Status,
    Quantity
FROM trading.[Order]
WHERE OrderId = @InvalidSellOrderId;


/*
Rezultat așteptat:

Stare = Pending
*/


/* =========================================================
   11. VERIFICĂ FAPTUL CĂ NU S-A CREAT NICIO EXECUȚIE
   ========================================================= */

SELECT
    ExecutionId,
    OrderId,
    ExecutedQuantity,
    ExecutionPrice
FROM trading.Execution
WHERE OrderId = @InvalidSellOrderId;


/*
Rezultat așteptat:

0 rânduri
*/


/* =========================================================
   12. VERIFICĂ POZIȚIA WAS NOT CHANGED
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


/*
Rezultat așteptat:

Cantitatea rămâne neschimbată după respingerea SELL.
*/


/* =========================================================
   13. CREEAZĂ TESTUL PREȚULUI LIMITĂ PENTRU SELL
   ========================================================= */

DECLARE @InvalidPriceSellId BIGINT;

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
    'SELL',
    'LIMIT',
    5,
    140,
    'Pending'
);

SET @InvalidPriceSellId = SCOPE_IDENTITY();


/* =========================================================
   14. EXECUTĂ SUB PREȚUL LIMITĂ
      SELL LIMIT 140
      Execuție preț 130
   ========================================================= */

BEGIN TRY

    EXEC trading.usp_ExecuteOrder
        @OrderId = @InvalidPriceSellId,
        @ExecutedQuantity = 5,
        @ExecutionPrice = 130;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


/*
Rezultat așteptat:

Execuția este respinsă deoarece:

ExecutionPrice < LimitPrice

130 < 140
*/


/* =========================================================
   15. VERIFICĂ REVENIREA VALIDĂRII PREȚULUI
   ========================================================= */

SELECT
    OrderId,
    Status,
    Quantity,
    LimitPrice
FROM trading.[Order]
WHERE OrderId = @InvalidPriceSellId;


/*
Rezultat așteptat:

Stare = Pending
*/


SELECT
    ExecutionId,
    OrderId,
    ExecutedQuantity,
    ExecutionPrice
FROM trading.Execution
WHERE OrderId = @InvalidPriceSellId;


/*
Rezultat așteptat:

0 rânduri
*/


/* =========================================================
   16. REZUMATUL FINAL AL TESTULUI
   ========================================================= */

SELECT
    N'TESTUL 10 - SELL + VALIDAREA POZIȚIEI' AS TestName,
    'PASS - if valid SELL executed, position decreased,
           invalid quantity was rejected, and invalid
           prețul LIMIT a fost respins.' AS ExpectedResult;
GO
