USE BrokerageDB;
GO

/* ============================================================
   Test #13 - ETL Failure / Marcaj temporal Revenire

   Obiectiv:
       Demonstrează că o rulare ETL eșuată:
       1. anulează modificările datelor
       2. NU avansează marcajul temporal
       3. este înregistrată cu starea Failed în ETLRunLog
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @EntityName VARCHAR(100) = 'Order';

DECLARE @WatermarkBefore DATETIME2(3);
DECLARE @WatermarkAfter  DATETIME2(3);

DECLARE @ETLRunId BIGINT;


/* ============================================================
   1. Memorează marcajul temporal ÎNAINTE de test
   ============================================================ */

SELECT
    @WatermarkBefore = LastSuccessfulLoad
FROM staging.ETLWatermark
WHERE EntityName = @EntityName;


IF @WatermarkBefore IS NULL
    THROW 52000, N'Marcajul temporal pentru Order nu există.', 1;


PRINT N'Marcaj temporal înainte de test:';

SELECT
    @EntityName AS EntityName,
    @WatermarkBefore AS WatermarkBefore;


/* ============================================================
   2. Creează jurnalul rulării ETL
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


/* ============================================================
   3. Pornește simularea ETL
   ============================================================ */

BEGIN TRY

    BEGIN TRANSACTION;


    /* --------------------------------------------------------
       Simulează activitatea ETL

       IMPORTANT:
       Această schimbare trebuie să dispară după rollback.
       -------------------------------------------------------- */

    UPDATE staging.[Order]
    SET ExtractedAt = SYSUTCDATETIME()
    WHERE OrderId =
    (
        SELECT MAX(OrderId)
        FROM staging.[Order]
    );


    /* --------------------------------------------------------
       Simulează avansarea marcajului temporal

       Și aceasta trebuie să dispară după rollback.
       -------------------------------------------------------- */

    UPDATE staging.ETLWatermark
    SET
        LastSuccessfulLoad = SYSUTCDATETIME(),
        UpdatedAt = SYSUTCDATETIME()
    WHERE EntityName = @EntityName;


    /* --------------------------------------------------------
       Forțează eșecul ETL
       -------------------------------------------------------- */

    THROW 52001, N'Eșec ETL simulat pentru testul de revenire.', 1;


    /* Această linie nu trebuie executată niciodată */

    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;


    /* --------------------------------------------------------
       Înregistrează eșecul ÎN AFARA tranzacției anulate
       -------------------------------------------------------- */

    UPDATE staging.ETLRunLog
    SET
        CompletedAt = SYSUTCDATETIME(),
        Status = 'Failed',
        ErrorMessage = ERROR_MESSAGE()
    WHERE ETLRunId = @ETLRunId;


    PRINT N'S-a produs eșecul ETL așteptat.';
    PRINT ERROR_MESSAGE();

END CATCH;


/* ============================================================
   4. Memorează marcajul temporal DUPĂ eșec
   ============================================================ */

SELECT
    @WatermarkAfter = LastSuccessfulLoad
FROM staging.ETLWatermark
WHERE EntityName = @EntityName;


/* ============================================================
   5. Verifică marcaj temporal rollback
   ============================================================ */

SELECT
    @EntityName AS EntityName,
    @WatermarkBefore AS WatermarkBefore,
    @WatermarkAfter AS WatermarkAfter,
    CASE
        WHEN @WatermarkBefore = @WatermarkAfter
            THEN 'PASS'
        ELSE 'FAIL'
    END AS WatermarkRollbackTest;


/* ============================================================
   6. Verifică jurnalul ETL eșuat
   ============================================================ */

SELECT
    ETLRunId,
    EntityName,
    StartedAt,
    CompletedAt,
    Status,
    RowsProcessed,
    ErrorMessage
FROM staging.ETLRunLog
WHERE ETLRunId = @ETLRunId;


/* ============================================================
   7. Automated assertions
   ============================================================ */

IF @WatermarkBefore <> @WatermarkAfter
    THROW 52002,
          N'TEST EȘUAT: Watermark changed after failed ETL.',
          1;


IF NOT EXISTS
(
    SELECT 1
    FROM staging.ETLRunLog
    WHERE ETLRunId = @ETLRunId
      AND Status = 'Failed'
)
    THROW 52003,
          N'TEST EȘUAT: ETL failure was not logged.',
          1;


PRINT N'============================================';
PRINT N'TESTUL #13 A TRECUT';
PRINT N'Revenirea ETL și protejarea marcajului temporal funcționează.';
PRINT N'============================================';
GO
