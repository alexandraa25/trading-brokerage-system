USE BrokerageDB;
GO

/* Încărcare incrementală de tip 1 pentru entitățile de referință modificabile. */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @CurrentWatermark DATETIME2(3) = SYSUTCDATETIME();
DECLARE @RowsProcessed BIGINT = 0;
DECLARE @ETLRunId BIGINT;

IF EXISTS
(
    SELECT required.EntityName
    FROM (VALUES ('Customer'), ('Account'), ('Market'), ('Instrument')) required(EntityName)
    LEFT JOIN staging.ETLWatermark watermark
        ON watermark.EntityName = required.EntityName
    WHERE watermark.EntityName IS NULL
)
    THROW 51010, N'Lipsesc unul sau mai multe marcaje temporale pentru dimensiuni.', 1;

INSERT INTO staging.ETLRunLog (EntityName, Status)
VALUES ('Dimensions', 'Running');

SET @ETLRunId = SCOPE_IDENTITY();

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE target
    SET CustomerTypeId = source.CustomerTypeId,
        FirstName = source.FirstName,
        LastName = source.LastName,
        Email = source.Email,
        Phone = source.Phone,
        DateOfBirth = source.DateOfBirth,
        Status = source.Status,
        CreatedAt = source.CreatedAt,
        UpdatedAt = source.UpdatedAt,
        ExtractedAt = SYSUTCDATETIME()
    FROM staging.Customer target
    INNER JOIN core.Customer source ON source.CustomerId = target.CustomerId
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Customer'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark;
    SET @RowsProcessed += @@ROWCOUNT;

    INSERT INTO staging.Customer
    (CustomerId, CustomerTypeId, FirstName, LastName, Email, Phone,
     DateOfBirth, Status, CreatedAt, UpdatedAt)
    SELECT source.CustomerId, source.CustomerTypeId, source.FirstName,
           source.LastName, source.Email, source.Phone, source.DateOfBirth,
           source.Status, source.CreatedAt, source.UpdatedAt
    FROM core.Customer source
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Customer'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark
      AND NOT EXISTS (SELECT 1 FROM staging.Customer target
                      WHERE target.CustomerId = source.CustomerId);
    SET @RowsProcessed += @@ROWCOUNT;

    UPDATE target
    SET CustomerId = source.CustomerId,
        AccountNumber = source.AccountNumber,
        Currency = source.Currency,
        Status = source.Status,
        CreatedAt = source.CreatedAt,
        UpdatedAt = source.UpdatedAt,
        ClosedAt = source.ClosedAt,
        ExtractedAt = SYSUTCDATETIME()
    FROM staging.Account target
    INNER JOIN core.Account source ON source.AccountId = target.AccountId
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Account'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark;
    SET @RowsProcessed += @@ROWCOUNT;

    INSERT INTO staging.Account
    (AccountId, CustomerId, AccountNumber, Currency, Status, CreatedAt,
     UpdatedAt, ClosedAt)
    SELECT source.AccountId, source.CustomerId, source.AccountNumber,
           source.Currency, source.Status, source.CreatedAt,
           source.UpdatedAt, source.ClosedAt
    FROM core.Account source
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Account'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark
      AND NOT EXISTS (SELECT 1 FROM staging.Account target
                      WHERE target.AccountId = source.AccountId);
    SET @RowsProcessed += @@ROWCOUNT;

    UPDATE target
    SET MarketCode = source.MarketCode,
        MarketName = source.MarketName,
        CountryCode = source.CountryCode,
        Currency = source.Currency,
        IsActive = source.IsActive,
        CreatedAt = source.CreatedAt,
        UpdatedAt = source.UpdatedAt,
        ExtractedAt = SYSUTCDATETIME()
    FROM staging.Market target
    INNER JOIN trading.Market source ON source.MarketId = target.MarketId
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Market'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark;
    SET @RowsProcessed += @@ROWCOUNT;

    INSERT INTO staging.Market
    (MarketId, MarketCode, MarketName, CountryCode, Currency, IsActive,
     CreatedAt, UpdatedAt)
    SELECT source.MarketId, source.MarketCode, source.MarketName,
           source.CountryCode, source.Currency, source.IsActive,
           source.CreatedAt, source.UpdatedAt
    FROM trading.Market source
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Market'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark
      AND NOT EXISTS (SELECT 1 FROM staging.Market target
                      WHERE target.MarketId = source.MarketId);
    SET @RowsProcessed += @@ROWCOUNT;

    UPDATE target
    SET MarketId = source.MarketId,
        IssuerId = source.IssuerId,
        Symbol = source.Symbol,
        InstrumentName = source.InstrumentName,
        InstrumentType = source.InstrumentType,
        Currency = source.Currency,
        IsActive = source.IsActive,
        CreatedAt = source.CreatedAt,
        UpdatedAt = source.UpdatedAt,
        ExtractedAt = SYSUTCDATETIME()
    FROM staging.Instrument target
    INNER JOIN trading.Instrument source
        ON source.InstrumentId = target.InstrumentId
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Instrument'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark;
    SET @RowsProcessed += @@ROWCOUNT;

    INSERT INTO staging.Instrument
    (InstrumentId, MarketId, IssuerId, Symbol, InstrumentName,
     InstrumentType, Currency, IsActive, CreatedAt, UpdatedAt)
    SELECT source.InstrumentId, source.MarketId, source.IssuerId,
           source.Symbol, source.InstrumentName, source.InstrumentType,
           source.Currency, source.IsActive, source.CreatedAt, source.UpdatedAt
    FROM trading.Instrument source
    CROSS JOIN staging.ETLWatermark watermark
    WHERE watermark.EntityName = 'Instrument'
      AND source.UpdatedAt > watermark.LastSuccessfulLoad
      AND source.UpdatedAt <= @CurrentWatermark
      AND NOT EXISTS (SELECT 1 FROM staging.Instrument target
                      WHERE target.InstrumentId = source.InstrumentId);
    SET @RowsProcessed += @@ROWCOUNT;

    UPDATE staging.ETLWatermark
    SET LastSuccessfulLoad = @CurrentWatermark,
        UpdatedAt = SYSUTCDATETIME()
    WHERE EntityName IN ('Customer', 'Account', 'Market', 'Instrument');

    UPDATE staging.ETLRunLog
    SET CompletedAt = SYSUTCDATETIME(),
        Status = 'Succeeded',
        RowsProcessed = @RowsProcessed
    WHERE ETLRunId = @ETLRunId;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    UPDATE staging.ETLRunLog
    SET CompletedAt = SYSUTCDATETIME(),
        Status = 'Failed',
        ErrorMessage = ERROR_MESSAGE()
    WHERE ETLRunId = @ETLRunId;

    THROW;
END CATCH;
GO
