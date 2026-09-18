USE BrokerageDB;
GO

/*
Test: Execuție dublă / condiție de cursă

Scop:
Demonstrează că același ordin nu poate fi executat
cu succes de două sesiuni concurente.

Test Ordin:
OrderId = 110007

Condiții inițiale:
- AccountId = 6
- CashAccountId = 8
- Sold inițial de numerar = 1000 USD
- Ordin stare = Pending
- Ordin cantitate = 5
- Limit preț = 100 USD

Așteptat comportament:
- Sesiunea A execută ordinul cu succes.
- Sesiunea B încearcă să execute același ordin.
- Sesiunea B eșuează deoarece ordinul este deja Executed.
- Este creată exact o înregistrare Execution.
- Cantitatea poziției este mărită o singură dată.
- Numerarul este redus o singură dată.

Scenariul de concurență necesită două sesiuni SSMS separate.

------------------------------------------------------------
SESIUNEA A
------------------------------------------------------------

USE BrokerageDB;
GO

EXEC trading.usp_ExecuteOrder
    @OrderId = 110007,
    @ExecutedQuantity = 5.00000000,
    @ExecutionPrice = 100.00000000;
GO

Rezultat așteptat:

OrderId          = 110007
ExecutedQuantity = 5
ExecutionPrice   = 100
TradeValue       = 500
Comision       = 1.25
Stare           = Executed


------------------------------------------------------------
SESIUNEA B
------------------------------------------------------------

USE BrokerageDB;
GO

EXEC trading.usp_ExecuteOrder
    @OrderId = 110007,
    @ExecutedQuantity = 5.00000000,
    @ExecutionPrice = 100.00000000;
GO

Rezultat așteptat:

Eroare 50013:
Ordinul nu poate fi executat în starea curentă.


------------------------------------------------------------
VALIDARE
------------------------------------------------------------

-- Verifică ordinul și numărul de execuții

SELECT
    o.OrderId,
    o.Status,
    o.Quantity,
    ISNULL(SUM(e.ExecutedQuantity), 0) AS TotalExecutedQuantity,
    COUNT(e.ExecutionId) AS ExecutionCount
FROM trading.[Order] o
LEFT JOIN trading.Execution e
    ON e.OrderId = o.OrderId
WHERE o.OrderId = 110007
GROUP BY
    o.OrderId,
    o.Status,
    o.Quantity;
GO


-- Verifică poziție

SELECT
    PositionId,
    AccountId,
    InstrumentId,
    Cantitate,
    AveragePrice
FROM trading.Position
WHERE AccountId = 6
  AND InstrumentId = 1;
GO


-- Verifică soldul de numerar

SELECT
    CashAccountId,
    AvailableBalance,
    BlockedBalance
FROM core.CashAccount
WHERE CashAccountId = 8;
GO


/*
Observat rezultat:

Ordin 110007:
- Stare = Executed
- TotalExecutedQuantity = 5
- ExecutionCount = 1

Poziție:
- Cantitate = 5
- AveragePrice = 100

Numerar:
- AvailableBalance = 498.75 USD

Calculation:

Inițial numerar       = 1000.00
Valoarea tranzacției        =  500.00
Comision (0.25%)=    1.25
Rămas numerar     =  498.75

Conclusion:

Încercarea concurentă de execuție nu a creat
a duplicat execuție.

Ordinul a fost executat exact o dată.
*/
