USE BrokerageDB;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   ETL #4 - Încărcare incrementală

   Entitate:
       trading.[Order] -> staging.[Order]

   Strategie:
       Marcaj temporal based on UpdatedAt

   Gestionează:
       - ordine noi
       - ordine actualizate
       - jurnalizare ETL
       - revenirea tranzacției
       - actualizarea marcajului temporal
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @EntityName VARCHAR(100) = 'Order';
DECLARE @LastSuccessfulLoad DATETIME2(3);
DECLARE @CurrentWatermark DATETIME2(3);
DECLARE @ETLRunId BIGINT;
DECLARE @RowsProcessed BIGINT = 0;


/* ============================================================
   1. Citește marcajul temporal anterior
   ============================================================ */

SELECT
    @LastSuccessfulLoad = LastSuccessfulLoad
FROM staging.ETLWatermark
WHERE EntityName = @EntityName;

IF @LastSuccessfulLoad IS NULL
    THROW 51000, N'Marcajul temporal pentru Order nu a fost găsit.', 1;


/* ============================================================
   2. Fixează marcajul temporal superior

   Important:
   Acesta este fixat ÎNAINTE de citirea rândurilor sursă.

   Astfel, ETL primește o fereastră fixă de procesare:

       LastSuccessfulLoad < UpdatedAt <= CurrentWatermark
   ============================================================ */

SET @CurrentWatermark = SYSUTCDATETIME();


/* ============================================================
   3. Înregistrează rularea ETL
   ============================================================ */

INSERT INTO staging.ETLRunLog
(
    EntityName,
    Status
)
VALUES
(
    @EntityName,
    'Running'
);

SET @ETLRunId = SCOPE_IDENTITY();


BEGIN TRY

    BEGIN TRANSACTION;


    /* ========================================================
       4. Actualizează rândurile deja prezente în staging
       ======================================================== */

    UPDATE target
    SET
        target.AccountId    = source.AccountId,
        target.InstrumentId = source.InstrumentId,
        target.Side         = source.Side,
        target.OrderType    = source.OrderType,
        target.Quantity     = source.Quantity,
        target.LimitPrice   = source.LimitPrice,
        target.Status       = source.Status,
        target.CreatedAt    = source.CreatedAt,
        target.UpdatedAt    = source.UpdatedAt,
        target.ExtractedAt  = SYSUTCDATETIME()
    FROM staging.[Order] AS target
    INNER JOIN trading.[Order] AS source
        ON source.OrderId = target.OrderId
    WHERE
        source.UpdatedAt > @LastSuccessfulLoad
        AND source.UpdatedAt <= @CurrentWatermark;

    SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;


    /* ========================================================
       5. Inserează rândurile noi
       ======================================================== */

    INSERT INTO staging.[Order]
    (
        OrderId,
        AccountId,
        InstrumentId,
        Side,
        OrderType,
        Quantity,
        LimitPrice,
        Status,
        CreatedAt,
        UpdatedAt
    )
    SELECT
        source.OrderId,
        source.AccountId,
        source.InstrumentId,
        source.Side,
        source.OrderType,
        source.Quantity,
        source.LimitPrice,
        source.Status,
        source.CreatedAt,
        source.UpdatedAt
    FROM trading.[Order] AS source
    WHERE
        source.UpdatedAt > @LastSuccessfulLoad
        AND source.UpdatedAt <= @CurrentWatermark

        AND NOT EXISTS
        (
            SELECT 1
            FROM staging.[Order] AS target
            WHERE target.OrderId = source.OrderId
        );

    SET @RowsProcessed = @RowsProcessed + @@ROWCOUNT;


    /* ========================================================
       6. Avansează marcajul temporal
       ======================================================== */

    UPDATE staging.ETLWatermark
    SET
        LastSuccessfulLoad = @CurrentWatermark,
        UpdatedAt = SYSUTCDATETIME()
    WHERE EntityName = @EntityName;


    /* ========================================================
       7. Finalizează jurnalul ETL
       ======================================================== */

    UPDATE staging.ETLRunLog
    SET
        CompletedAt   = SYSUTCDATETIME(),
        Status        = 'Succeeded',
        RowsProcessed = @RowsProcessed
    WHERE ETLRunId = @ETLRunId;


    COMMIT TRANSACTION;


    PRINT N'Încărcarea incrementală pentru Order s-a finalizat cu succes.';

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;


    /* ETLRunLog a fost creat înaintea tranzacției,
       astfel încât rularea eșuată să poată fi înregistrată. */

    UPDATE staging.ETLRunLog
    SET
        CompletedAt  = SYSUTCDATETIME(),
        Status       = 'Failed',
        ErrorMessage = ERROR_MESSAGE()
    WHERE ETLRunId = @ETLRunId;


    THROW;

END CATCH;
GO

/* ============================================================
   DEMONSTRAȚIE MANUALĂ (dezactivată)

   Aceste instrucțiuni au numai rol de documentație. ETL-ul de producție nu trebuie
   să creeze sau să anuleze ordine operaționale ca efect secundar.
   ============================================================


SELECT *
FROM staging.ETLWatermark
WHERE EntityName = 'Order';


SELECT
    ETLRunId,
    EntityName,
    StartedAt,
    CompletedAt,
    Status,
    RowsProcessed,
    ErrorMessage
FROM staging.ETLRunLog
ORDER BY ETLRunId DESC;

/* ============================================================
   TEST DE INSERARE
   ============================================================ */


SELECT TOP (5)
    AccountId,
    AccountNumber,
    Status
FROM core.Account;

SELECT TOP (5)
    InstrumentId,
    Symbol,
    InstrumentName
FROM trading.Instrument;

--Alege un cont activ și un instrument valid.

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
    5,              
    1,
    'BUY',
    'LIMIT',
    3,
    125.00,
    'Pending'
);

DECLARE @NewOrderId BIGINT = SCOPE_IDENTITY();

SELECT *
FROM trading.[Order]
WHERE OrderId = @NewOrderId;

SELECT MAX(OrderId) AS MaxStagingOrder
FROM staging.[Order];


SELECT TOP (10)
    OrderId,
    AccountId,
    InstrumentId,
    Side,
    Quantity,
    Status,
    UpdatedAt,
    ExtractedAt
FROM staging.[Order]
ORDER BY OrderId DESC;

SELECT TOP (5)
    ETLRunId,
    EntityName,
    Status,
    RowsProcessed,
    StartedAt,
    CompletedAt
FROM staging.ETLRunLog
ORDER BY ETLRunId DESC;


/* ============================================================
   TEST DE ACTUALIZARE
   ============================================================ */

   --Luăm ordin-ul creat

   DECLARE @OrderId BIGINT =
(
    SELECT MAX(OrderId)
    FROM trading.[Order]
);

UPDATE trading.[Order]
SET
    Status = 'Cancelled',
    UpdatedAt = SYSUTCDATETIME()
WHERE OrderId = @OrderId;

SELECT
    OrderId,
    Status,
    UpdatedAt
FROM trading.[Order]
WHERE OrderId = @OrderId;

--Înainte de ETL, verifică staging. Ar trebui să fie încă Pending

SELECT
    OrderId,
    Status,
    UpdatedAt
FROM staging.[Order]
WHERE OrderId =
(
    SELECT MAX(OrderId)
    FROM trading.[Order]
);

--Rulează iar: 04_incremental_load.sql, și apoi:

SELECT
    OrderId,
    Status,
    UpdatedAt,
    ExtractedAt
FROM staging.[Order]
WHERE OrderId =
(
    SELECT MAX(OrderId)
    FROM trading.[Order]
);

--Acum trebuie să fie: Cancelled. 
--Iar ultima execuție ETL ar trebui din nou să aibă: RowsProcessed = 1
*/
