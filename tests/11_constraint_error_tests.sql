USE BrokerageDB;
GO

/*
===========================================================
TEST 11 - TESTE PENTRU CONSTRÂNGERI ȘI ERORI
===========================================================

Scop:
- Verifică constrângerile PRIMARY KEY
- Verifică constrângerile FOREIGN KEY
- Verifică constrângerile UNIQUE
- Verifică constrângerile CHECK
- Verifică NOT NULL constraints
- Verifică faptul că datele de business invalide nu pot intra în bază

Important:
Fiecare INSERT invalid este încadrat în TRY/CATCH, astfel încât
o eroare așteptată să nu oprească întregul test.
===========================================================
*/


/* =========================================================
   TEST 11.1 - PRIMARY KEY
   Duplicat CustomerTypeId
   ========================================================= */

PRINT N'TEST 11.1 - PRIMARY KEY';

BEGIN TRY

    INSERT INTO core.CustomerType
    (
        CustomerTypeId,
        Code,
        Name
    )
    VALUES
    (
        1,
        'DUPLICATE',
        'Duplicate Customer Type'
    );

    PRINT N'EROARE: cheia primară duplicată a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'PRIMARY KEY a respins CustomerTypeId duplicat' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.2 - UNIQUE
   E-mail de client duplicat
   ========================================================= */

PRINT N'TEST 11.2 - e-mail Customer unic';

BEGIN TRY

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
        'Duplicate',
        'Customer',
        'alex@example.test',
        '0700000000',
        '1990-01-01',
        'Active'
    );

    PRINT N'EROARE: adresa de e-mail duplicată a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea UNIQUE a respins e-mailul duplicat' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.3 - FOREIGN KEY
   CustomerTypeId invalid
   ========================================================= */

PRINT N'TEST 11.3 - FOREIGN KEY';

BEGIN TRY

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
        999999,
        'Invalid',
        'FK',
        'invalid.fk@example.test',
        '0700000000',
        '1990-01-01',
        'Active'
    );

    PRINT N'EROARE: cheia externă invalidă a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'FOREIGN KEY a respins CustomerTypeId invalid' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.4 - CHECK
   Stare de client invalidă
   ========================================================= */

PRINT N'TEST 11.4 - verificarea stării Customer';

BEGIN TRY

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
        'Invalid',
        'Status',
        'invalid.status@example.test',
        '0700000000',
        '1990-01-01',
        'INVALID_STATUS'
    );

    PRINT N'EROARE: starea invalidă a clientului a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins starea invalidă Customer' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.5 - CHECK
   Negativ Ordin Cantitate
   ========================================================= */

PRINT N'TEST 11.5 - verificarea cantității Order';

BEGIN TRY

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
        -10,
        150,
        'Pending'
    );

    PRINT N'EROARE: cantitatea negativă a ordinului a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins cantitatea negativă a ordinului' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.6 - CHECK
   Direcție invalidă a ordinului
   ========================================================= */

PRINT N'TEST 11.6 - verificarea direcției Order';

BEGIN TRY

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
        'INVALID',
        'LIMIT',
        10,
        150,
        'Pending'
    );

    PRINT N'EROARE: direcția invalidă a ordinului a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins direcția invalidă Order' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.7 - CHECK
   Tip invalid de ordin
   ========================================================= */

PRINT N'TEST 11.7 - verificarea tipului Order';

BEGIN TRY

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
        'INVALID',
        10,
        150,
        'Pending'
    );

    PRINT N'EROARE: tipul invalid al ordinului a fost acceptat.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins tipul invalid Order' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.8 - CHECK
   LIMIT ordin fără LimitPrice
   ========================================================= */

PRINT N'TEST 11.8 - Order LIMIT fără LimitPrice';

BEGIN TRY

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
        NULL,
        'Pending'
    );

    PRINT N'EROARE: ordinul LIMIT fără LimitPrice a fost acceptat.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins ordinul LIMIT fără preț' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.9 - CHECK
   Negativ Execuție Cantitate
   ========================================================= */

PRINT N'TEST 11.9 - cantitatea Execution';

BEGIN TRY

    INSERT INTO trading.Execution
    (
        OrderId,
        ExecutedQuantity,
        ExecutionPrice
    )
    VALUES
    (
        1,
        -5,
        100
    );

    PRINT N'EROARE: cantitatea negativă a execuției a fost acceptată.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins cantitatea negativă a execuției' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.10 - CHECK
   Negativ Execuție Preț
   ========================================================= */

PRINT N'TEST 11.10 - prețul Execution';

BEGIN TRY

    INSERT INTO trading.Execution
    (
        OrderId,
        ExecutedQuantity,
        ExecutionPrice
    )
    VALUES
    (
        1,
        5,
        -100
    );

    PRINT N'EROARE: prețul negativ al execuției a fost acceptat.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'Constrângerea CHECK a respins prețul negativ al execuției' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.11 - FOREIGN KEY
   InstrumentId invalid
   ========================================================= */

PRINT N'TEST 11.11 - FOREIGN KEY Instrument';

BEGIN TRY

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
        999999,
        'BUY',
        'LIMIT',
        10,
        150,
        'Pending'
    );

    PRINT N'EROARE: InstrumentId invalid a fost acceptat.';

END TRY
BEGIN CATCH

    SELECT
        'PASS' AS Result,
        N'FOREIGN KEY a respins InstrumentId invalid' AS Test;

    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;

END CATCH;
GO


/* =========================================================
   TEST 11.12 - VERIFICARE FINALĂ A INTEGRITĂȚII DATELOR
   ========================================================= */

PRINT N'TEST 11.12 - Verificarea finală a integrității datelor';

SELECT
    COUNT(*) AS InvalidOrders
FROM trading.[Order]
WHERE Quantity <= 0
   OR Side NOT IN ('BUY', 'SELL')
   OR OrderType NOT IN ('MARKET', 'LIMIT')
   OR Status NOT IN
      (
          'Pending',
          'PartiallyExecuted',
          'Executed',
          'Cancelled',
          'Rejected'
      );


/*
Rezultat așteptat:

InvalidOrders = 0
*/


/* =========================================================
   REZUMAT FINAL
   ========================================================= */

SELECT
    N'TESTUL 11 - CONSTRÂNGERI ȘI ERORI' AS TestName,
    'PASS if all invalid INSERT operations were rejected
     și InvalidOrders = 0.' AS ExpectedResult;
GO
