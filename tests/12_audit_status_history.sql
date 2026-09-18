USE BrokerageDB;
GO

/*
===========================================================
TEST 12 - AUDIT ȘI ISTORICUL STĂRII ORDINULUI
===========================================================

Scop:
- Verifică OrderStatusHistory trigger
- Verifică Pending -> PartiallyExecuted transition
- Verifică tranziția PartiallyExecuted -> Executed
- Verifică old/nou stare values
- Verifică ChangedBy is populated
- Verifică faptul că un UPDATE fără legătură nu creează un rând de istoric

Așteptat stare transitions:

    Pending
       |
       v
    PartiallyExecuted
       |
       v
    Executed

Așteptat istoric rânduri:

    Pending -> PartiallyExecuted
    PartiallyExecuted -> Executed
===========================================================
*/


/* =========================================================
   1. CREEAZĂ ORDINUL DE TEST
   ========================================================= */

DECLARE @OrderId BIGINT;

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
    10,
    160,
    'Pending'
);

SET @OrderId = SCOPE_IDENTITY();


SELECT
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    OrderType,
    Quantity,
    LimitPrice,
    Status,
    CreatedAt
FROM trading.[Order]
WHERE OrderId = @OrderId;


/*
Rezultat așteptat:

Stare = Pending
*/


/* =========================================================
   2. VERIFICĂ ISTORICUL ÎNAINTEA SCHIMBĂRII STĂRII
   ========================================================= */

SELECT
    OrderStatusHistoryId,
    OrderId,
    OldStatus,
    NewStatus,
    ChangedBy,
    ChangedAt
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId
ORDER BY ChangedAt, OrderStatusHistoryId;


/*
Rezultat așteptat:

0 rânduri

Triggerul trebuie să înregistreze numai schimbările de stare,
nu și inserarea inițială.
*/


/* =========================================================
   3. SCHIMBĂ STAREA:
      Pending -> PartiallyExecuted
   ========================================================= */

UPDATE trading.[Order]
SET Status = 'PartiallyExecuted'
WHERE OrderId = @OrderId;


/* =========================================================
   4. VERIFICĂ STAREA ORDINULUI
   ========================================================= */

SELECT
    OrderId,
    Status
FROM trading.[Order]
WHERE OrderId = @OrderId;


/*
Rezultat așteptat:

PartiallyExecuted
*/


/* =========================================================
   5. VERIFICĂ PRIMA ÎNREGISTRARE DE AUDIT
   ========================================================= */

SELECT
    OrderStatusHistoryId,
    OrderId,
    OldStatus,
    NewStatus,
    ChangedBy,
    ChangedAt
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId
ORDER BY ChangedAt, OrderStatusHistoryId;


/*
Rezultat așteptat:

OldStatus = Pending
NewStatus = PartiallyExecuted
*/


/* =========================================================
   6. SCHIMBĂ STAREA:
      PartiallyExecuted -> Executed
   ========================================================= */

UPDATE trading.[Order]
SET Status = 'Executed'
WHERE OrderId = @OrderId;


/* =========================================================
   7. VERIFICĂ A DOUA ÎNREGISTRARE DE AUDIT
   ========================================================= */

SELECT
    OrderStatusHistoryId,
    OrderId,
    OldStatus,
    NewStatus,
    ChangedBy,
    ChangedAt
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId
ORDER BY ChangedAt, OrderStatusHistoryId;


/*
Rezultat așteptat:

Row 1:
Pending -> PartiallyExecuted

Row 2:
PartiallyExecuted -> Executed
*/


/* =========================================================
   8. VERIFICĂ NUMĂRUL EXACT DE RÂNDURI DIN ISTORIC
   ========================================================= */

SELECT
    COUNT(*) AS HistoryRowCount
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId;


/*
Rezultat așteptat:

HistoryRowCount = 2
*/


/* =========================================================
   9. VERIFICĂ CHANGEDBY
   ========================================================= */

SELECT
    OrderStatusHistoryId,
    OrderId,
    OldStatus,
    NewStatus,
    ChangedBy,
    ChangedAt
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId
  AND ChangedBy IS NULL;


/*
Rezultat așteptat:

0 rânduri

ChangedBy trebuie populat prin SUSER_SNAME().
*/


/* =========================================================
   10. TESTEAZĂ UN UPDATE FĂRĂ LEGĂTURĂ
       Actualizarea LimitPrice NU trebuie să creeze
       another stare-istoric row.
   ========================================================= */

UPDATE trading.[Order]
SET LimitPrice = 159
WHERE OrderId = @OrderId;


/* =========================================================
   11. VERIFICĂ FAPTUL CĂ NUMĂRUL DIN ISTORIC NU S-A SCHIMBAT
   ========================================================= */

SELECT
    COUNT(*) AS HistoryRowCount
FROM audit.OrderStatusHistory
WHERE OrderId = @OrderId;


/*
Rezultat așteptat:

HistoryRowCount = 2

Triggerul trebuie să reacționeze numai când Status se schimbă.
*/


/* =========================================================
   12. VERIFICĂ ORDINUL FINAL
   ========================================================= */

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


/*
Rezultat așteptat:

Stare     = Executed
LimitPrice = 159
*/


/* =========================================================
   13. RAPORT FINAL DE AUDIT
   ========================================================= */

SELECT
    h.OrderStatusHistoryId,
    h.OrderId,
    h.OldStatus,
    h.NewStatus,
    h.ChangedBy,
    h.ChangedAt
FROM audit.OrderStatusHistory h
WHERE h.OrderId = @OrderId
ORDER BY h.ChangedAt, h.OrderStatusHistoryId;


/* =========================================================
   14. VERIFICARE AUTOMATĂ A REZULTATULUI
   ========================================================= */

IF
(
    SELECT COUNT(*)
    FROM audit.OrderStatusHistory
    WHERE OrderId = @OrderId
) <> 2
BEGIN
    THROW 51100,
        N'TEST 12 FAILED: Expected exactly 2 status history records.',
        1;
END;


IF NOT EXISTS
(
    SELECT 1
    FROM audit.OrderStatusHistory
    WHERE OrderId = @OrderId
      AND OldStatus = 'Pending'
      AND NewStatus = 'PartiallyExecuted'
)
BEGIN
    THROW 51101,
        N'TEST 12 FAILED: Pending -> PartiallyExecuted transition missing.',
        1;
END;


IF NOT EXISTS
(
    SELECT 1
    FROM audit.OrderStatusHistory
    WHERE OrderId = @OrderId
      AND OldStatus = 'PartiallyExecuted'
      AND NewStatus = 'Executed'
)
BEGIN
    THROW 51102,
        N'TEST 12 FAILED: tranziția PartiallyExecuted -> Executed missing.',
        1;
END;


IF EXISTS
(
    SELECT 1
    FROM audit.OrderStatusHistory
    WHERE OrderId = @OrderId
      AND ChangedBy IS NULL
)
BEGIN
    THROW 51103,
        N'TEST 12 FAILED: ChangedBy contains NULL.',
        1;
END;


PRINT N'TESTUL 12 A TRECUT - istoricul stării ordinului funcționează corect.';
GO
