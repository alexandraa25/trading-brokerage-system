USE BrokerageDB;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   ETL #5 - Încărcare incrementală pentru entități numai cu adăugare

   Entități:
       trading.Execution       -> staging.Execution
       trading.CashTransaction -> staging.CashTransaction

   Strategie:
       CreatedAt marcaj temporal

   Funcționalități:
       - extragere incrementală
       - protecție împotriva duplicatelor
       - jurnalizarea rulării ETL
       - revenirea tranzacției
       - avansarea sigură a marcajului temporal
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;


/* ============================================================
   PARTEA 1 - EXECUȚIE
   ============================================================ */

DECLARE @ExecutionEntity VARCHAR(100) = 'Execution';
DECLARE @ExecutionLastWatermark DATETIME2(3);
DECLARE @ExecutionCurrentWatermark DATETIME2(3);
DECLARE @ExecutionRunId BIGINT;
DECLARE @ExecutionRows BIGINT = 0;


SELECT
    @ExecutionLastWatermark = LastSuccessfulLoad
FROM staging.ETLWatermark
WHERE EntityName = @ExecutionEntity;

IF @ExecutionLastWatermark IS NULL
    THROW 51100, N'Marcajul temporal pentru Execution nu a fost găsit.', 1;


SET @ExecutionCurrentWatermark = SYSUTCDATETIME();


INSERT INTO staging.ETLRunLog
(
    EntityName,
    Status
)
VALUES
(
    @ExecutionEntity,
    'Running'
);

SET @ExecutionRunId = SCOPE_IDENTITY();


BEGIN TRY

    BEGIN TRANSACTION;


    /* --------------------------------------------------------
       Inserează numai execuțiile noi
       -------------------------------------------------------- */

    INSERT INTO staging.Execution
    (
        ExecutionId,
        OrderId,
        ExecutedQuantity,
        ExecutionPrice,
        ExecutedAt,
        CreatedAt,
        TradeCurrency,
        ReportingCurrency,
        ExchangeRateToReporting,
        ExchangeRateDate,
        ExchangeRateSource,
        TradeValueReporting,
        CommissionReporting
    )
    SELECT
        source.ExecutionId,
        source.OrderId,
        source.ExecutedQuantity,
        source.ExecutionPrice,
        source.ExecutedAt,
        source.CreatedAt,
        source.TradeCurrency,
        source.ReportingCurrency,
        source.ExchangeRateToReporting,
        source.ExchangeRateDate,
        source.ExchangeRateSource,
        source.TradeValueReporting,
        source.CommissionReporting
    FROM trading.Execution AS source
    WHERE
        source.CreatedAt > @ExecutionLastWatermark
        AND source.CreatedAt <= @ExecutionCurrentWatermark

        AND NOT EXISTS
        (
            SELECT 1
            FROM staging.Execution AS target
            WHERE target.ExecutionId = source.ExecutionId
        );


    SET @ExecutionRows = @@ROWCOUNT;


    /* --------------------------------------------------------
       Avansează marcajul pentru Execuție
       -------------------------------------------------------- */

    UPDATE staging.ETLWatermark
    SET
        LastSuccessfulLoad = @ExecutionCurrentWatermark,
        UpdatedAt = SYSUTCDATETIME()
    WHERE EntityName = @ExecutionEntity;


    /* --------------------------------------------------------
       Marchează rularea ETL drept reușită
       -------------------------------------------------------- */

    UPDATE staging.ETLRunLog
    SET
        CompletedAt   = SYSUTCDATETIME(),
        Status        = 'Succeeded',
        RowsProcessed = @ExecutionRows
    WHERE ETLRunId = @ExecutionRunId;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;


    UPDATE staging.ETLRunLog
    SET
        CompletedAt  = SYSUTCDATETIME(),
        Status       = 'Failed',
        ErrorMessage = ERROR_MESSAGE()
    WHERE ETLRunId = @ExecutionRunId;


    THROW;

END CATCH;


/* ============================================================
   PARTEA 2 - TRANZACȚIE DE NUMERAR
   ============================================================ */

DECLARE @CashEntity VARCHAR(100) = 'CashTransaction';
DECLARE @CashLastWatermark DATETIME2(3);
DECLARE @CashCurrentWatermark DATETIME2(3);
DECLARE @CashRunId BIGINT;
DECLARE @CashRows BIGINT = 0;


SELECT
    @CashLastWatermark = LastSuccessfulLoad
FROM staging.ETLWatermark
WHERE EntityName = @CashEntity;

IF @CashLastWatermark IS NULL
    THROW 51200, N'Marcajul temporal pentru CashTransaction nu a fost găsit.', 1;


SET @CashCurrentWatermark = SYSUTCDATETIME();


INSERT INTO staging.ETLRunLog
(
    EntityName,
    Status
)
VALUES
(
    @CashEntity,
    'Running'
);

SET @CashRunId = SCOPE_IDENTITY();


BEGIN TRY

    BEGIN TRANSACTION;


    /* --------------------------------------------------------
       Inserează numai tranzacțiile de numerar noi
       -------------------------------------------------------- */

    INSERT INTO staging.CashTransaction
    (
        CashTransactionId,
        CashAccountId,
        TransactionType,
        Amount,
        Currency,
        ReferenceType,
        ReferenceId,
        Description,
        CreatedAt
    )
    SELECT
        source.CashTransactionId,
        source.CashAccountId,
        source.TransactionType,
        source.Amount,
        source.Currency,
        source.ReferenceType,
        source.ReferenceId,
        source.Description,
        source.CreatedAt
    FROM trading.CashTransaction AS source
    WHERE
        source.CreatedAt > @CashLastWatermark
        AND source.CreatedAt <= @CashCurrentWatermark

        AND NOT EXISTS
        (
            SELECT 1
            FROM staging.CashTransaction AS target
            WHERE target.CashTransactionId =
                  source.CashTransactionId
        );


    SET @CashRows = @@ROWCOUNT;


    /* --------------------------------------------------------
       Avansează marcajul pentru CashTransaction
       -------------------------------------------------------- */

    UPDATE staging.ETLWatermark
    SET
        LastSuccessfulLoad = @CashCurrentWatermark,
        UpdatedAt = SYSUTCDATETIME()
    WHERE EntityName = @CashEntity;


    /* --------------------------------------------------------
       Marchează rularea ETL drept reușită
       -------------------------------------------------------- */

    UPDATE staging.ETLRunLog
    SET
        CompletedAt   = SYSUTCDATETIME(),
        Status        = 'Succeeded',
        RowsProcessed = @CashRows
    WHERE ETLRunId = @CashRunId;


    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;


    UPDATE staging.ETLRunLog
    SET
        CompletedAt  = SYSUTCDATETIME(),
        Status       = 'Failed',
        ErrorMessage = ERROR_MESSAGE()
    WHERE ETLRunId = @CashRunId;


    THROW;

END CATCH;


PRINT N'Încărcările incrementale numai cu adăugare s-au finalizat cu succes.';
GO



/* ============================================================
   DEMONSTRAȚIE MANUALĂ (dezactivată)

   Aceste instrucțiuni au numai rol de documentație. ETL-ul de producție nu trebuie
   să creeze depozite ca efect secundar.
   ============================================================


   SELECT
    EntityName,
    LastSuccessfulLoad,
    UpdatedAt
FROM staging.ETLWatermark
WHERE EntityName IN
(
    'Execution',
    'CashTransaction'
);

--Ambele watermarks trebuie să se mute din 1900-01-01 la momentul actual.

--Verifică log-ul. Ar trebui să apară două rulări noi

SELECT TOP (10)
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
   TEST 2 - idempotency
   ============================================================ */

/* Rulează imediat încă o dată: 06_incremental_append_only.sql
   Dacă nu s-a produs nicio tranzacție între timp, ultimele două rulări trebuie să fie:
       Execuție          Succeeded     0
       CashTransaction    Succeeded     0

   Asta demonstrează o proprietate foarte bună pentru portofoliu: rerularea ETL nu duplică datele existente.
   Putem verifica explicit duplicatele: */

SELECT
    ExecutionId,
    COUNT(*) AS DuplicateCount
FROM staging.Execution
GROUP BY ExecutionId
HAVING COUNT(*) > 1;


SELECT
    CashTransactionId,
    COUNT(*) AS DuplicateCount
FROM staging.CashTransaction
GROUP BY CashTransactionId
HAVING COUNT(*) > 1;

-- Ambele query-uri trebuie să returneze: 0 rânduri


/* ============================================================
   TEST 3 - CashTransaction nou
   ============================================================ */
  
  SELECT
    CashAccountId,
    AccountId,
    Currency,
    AvailableBalance
FROM core.CashAccount
ORDER BY CashAccountId;

EXEC trading.usp_DepositCash
    @CashAccountId = 8,
    @Amount = 100.00,
    @Description = 'ETL incremental test';

    SELECT TOP (1)
    CashTransactionId,
    CashAccountId,
    TransactionType,
    Amount,
    Currency,
    Description,
    CreatedAt
FROM trading.CashTransaction
ORDER BY CashTransactionId DESC;

SELECT TOP (5)
    CashTransactionId,
    CashAccountId,
    TransactionType,
    Amount,
    Currency,
    Description,
    CreatedAt,
    ExtractedAt
FROM staging.CashTransaction
ORDER BY CashTransactionId DESC;
*/
