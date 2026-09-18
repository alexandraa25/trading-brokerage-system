USE BrokerageDW;
GO

/* ============================================================
   Sistem de baze de date pentru tranzacționare și brokeraj
   DW #4 - Încarcă dimensiunile

   Sursă:
       BrokerageDB.staging.*

   Destinație:
       BrokerageDW.dw.*

   Dimensiuni:
       DimDate
       DimCustomer
       DimAccount
       DimInstrument
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;


/* ============================================================
   PARTEA 1 - ÎNCARCĂ DimDate

   Interval calendaristic:
       2020-01-01 -> 2035-12-31
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM dw.DimDate
)
BEGIN

    DECLARE @CurrentDate DATE = '20200101';
    DECLARE @EndDate DATE = '20351231';

    WHILE @CurrentDate <= @EndDate
    BEGIN

        INSERT INTO dw.DimDate
        (
            DateKey,
            FullDate,
            DayNumber,
            DayName,
            MonthNumber,
            MonthName,
            QuarterNumber,
            YearNumber,
            YearMonth,
            IsWeekend
        )
        VALUES
        (
            CONVERT
            (
                INT,
                CONVERT
                (
                    CHAR(8),
                    @CurrentDate,
                    112
                )
            ),

            @CurrentDate,

            DAY(@CurrentDate),

            DATENAME
            (
                WEEKDAY,
                @CurrentDate
            ),

            MONTH(@CurrentDate),

            DATENAME
            (
                MONTH,
                @CurrentDate
            ),

            DATEPART
            (
                QUARTER,
                @CurrentDate
            ),

            YEAR(@CurrentDate),

            CONVERT
            (
                CHAR(7),
                @CurrentDate,
                126
            ),

            CASE
                WHEN DATEDIFF
                     (
                         DAY,
                         '19000101',
                         @CurrentDate
                     ) % 7 IN (5, 6)
                    THEN 1
                ELSE 0
            END
        );

        SET @CurrentDate =
            DATEADD(DAY, 1, @CurrentDate);

    END;

END;


/* ============================================================
   PARTEA 2 - ÎNCARCĂ DimCustomer

   Strategie:
       Dimensiune de tip 1

   Client existent:
       UPDATE

   Client nou:
       INSERT
   ============================================================ */

UPDATE target
SET
    target.CustomerTypeId  = source.CustomerTypeId,
    target.FirstName       = source.FirstName,
    target.LastName        = source.LastName,

    target.FullName =
        CONCAT
        (
            source.FirstName,
            ' ',
            source.LastName
        ),

    target.Email            = source.Email,
    target.DateOfBirth      = source.DateOfBirth,
    target.CustomerStatus   = source.Status,
    target.SourceCreatedAt  = source.CreatedAt,
    target.SourceUpdatedAt  = source.UpdatedAt,
    target.DWUpdatedAt      = SYSUTCDATETIME()

FROM dw.DimCustomer AS target

INNER JOIN BrokerageDB.staging.Customer AS source
    ON source.CustomerId = target.CustomerId;


INSERT INTO dw.DimCustomer
(
    CustomerId,
    CustomerTypeId,
    FirstName,
    LastName,
    FullName,
    Email,
    DateOfBirth,
    CustomerStatus,
    SourceCreatedAt,
    SourceUpdatedAt
)
SELECT
    source.CustomerId,
    source.CustomerTypeId,
    source.FirstName,
    source.LastName,

    CONCAT
    (
        source.FirstName,
        ' ',
        source.LastName
    ),

    source.Email,
    source.DateOfBirth,
    source.Status,
    source.CreatedAt,
    source.UpdatedAt

FROM BrokerageDB.staging.Customer AS source

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimCustomer AS target
    WHERE target.CustomerId = source.CustomerId
);


/* ============================================================
   PARTEA 5 - ÎNCARCĂ DimCurrency
   ============================================================ */

MERGE dw.DimCurrency AS target
USING BrokerageDB.core.Currency AS source
    ON source.CurrencyCode = target.CurrencyCode
WHEN MATCHED THEN
    UPDATE SET
        CurrencyName = source.CurrencyName,
        MinorUnit = source.MinorUnit,
        IsActive = source.IsActive,
        IsReportingCurrency = source.IsReportingCurrency,
        SourceUpdatedAt = source.UpdatedAt,
        DWUpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT
    (
        CurrencyCode, CurrencyName, MinorUnit, IsActive,
        IsReportingCurrency, SourceUpdatedAt
    )
    VALUES
    (
        source.CurrencyCode, source.CurrencyName, source.MinorUnit,
        source.IsActive, source.IsReportingCurrency, source.UpdatedAt
    );


/* ============================================================
   PARTEA 3 - ÎNCARCĂ DimAccount
   ============================================================ */

UPDATE target
SET
    target.CustomerId      = source.CustomerId,
    target.AccountNumber   = source.AccountNumber,
    target.Currency        = source.Currency,
    target.AccountStatus   = source.Status,
    target.SourceCreatedAt = source.CreatedAt,
    target.ClosedAt        = source.ClosedAt,
    target.DWUpdatedAt     = SYSUTCDATETIME()

FROM dw.DimAccount AS target

INNER JOIN BrokerageDB.staging.Account AS source
    ON source.AccountId = target.AccountId;


INSERT INTO dw.DimAccount
(
    AccountId,
    CustomerId,
    AccountNumber,
    Currency,
    AccountStatus,
    SourceCreatedAt,
    ClosedAt
)
SELECT
    source.AccountId,
    source.CustomerId,
    source.AccountNumber,
    source.Currency,
    source.Status,
    source.CreatedAt,
    source.ClosedAt

FROM BrokerageDB.staging.Account AS source

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimAccount AS target
    WHERE target.AccountId = source.AccountId
);


/* ============================================================
   PARTEA 4 - ÎNCARCĂ DimInstrument

   Instrument și Market sunt denormalizate într-o singură dimensiune.
   ============================================================ */

UPDATE target
SET
    target.Symbol             = instrument.Symbol,
    target.InstrumentName     = instrument.InstrumentName,
    target.InstrumentType     = instrument.InstrumentType,
    target.InstrumentCurrency = instrument.Currency,

    target.MarketId           = market.MarketId,
    target.MarketCode         = market.MarketCode,
    target.MarketName         = market.MarketName,
    target.MarketCountryCode  = market.CountryCode,
    target.MarketCurrency     = market.Currency,

    target.IsActive           = instrument.IsActive,
    target.SourceCreatedAt    = instrument.CreatedAt,
    target.DWUpdatedAt        = SYSUTCDATETIME()

FROM dw.DimInstrument AS target

INNER JOIN BrokerageDB.staging.Instrument AS instrument
    ON instrument.InstrumentId =
       target.InstrumentId

INNER JOIN BrokerageDB.staging.Market AS market
    ON market.MarketId =
       instrument.MarketId;


INSERT INTO dw.DimInstrument
(
    InstrumentId,
    Symbol,
    InstrumentName,
    InstrumentType,
    InstrumentCurrency,

    MarketId,
    MarketCode,
    MarketName,
    MarketCountryCode,
    MarketCurrency,

    IsActive,
    SourceCreatedAt
)
SELECT
    instrument.InstrumentId,
    instrument.Symbol,
    instrument.InstrumentName,
    instrument.InstrumentType,
    instrument.Currency,

    market.MarketId,
    market.MarketCode,
    market.MarketName,
    market.CountryCode,
    market.Currency,

    instrument.IsActive,
    instrument.CreatedAt

FROM BrokerageDB.staging.Instrument AS instrument

INNER JOIN BrokerageDB.staging.Market AS market
    ON market.MarketId =
       instrument.MarketId

WHERE NOT EXISTS
(
    SELECT 1
    FROM dw.DimInstrument AS target
    WHERE target.InstrumentId =
          instrument.InstrumentId
);


PRINT N'Încărcarea dimensiunilor s-a finalizat cu succes.';
GO




SELECT 'DimDate' AS TableName, COUNT(*) AS TotalRows
FROM dw.DimDate

UNION ALL

SELECT 'DimCustomer', COUNT(*)
FROM dw.DimCustomer

UNION ALL

SELECT 'DimAccount', COUNT(*)
FROM dw.DimAccount

UNION ALL

SELECT 'DimInstrument', COUNT(*)
FROM dw.DimInstrument

UNION ALL

SELECT 'DimCurrency', COUNT(*)
FROM dw.DimCurrency;



SELECT
    (SELECT COUNT(*)
     FROM BrokerageDB.staging.Customer) AS StagingCustomers,

    (SELECT COUNT(*)
     FROM dw.DimCustomer) AS DWCustomers;


SELECT
    (SELECT COUNT(*)
     FROM BrokerageDB.staging.Account) AS StagingAccounts,

    (SELECT COUNT(*)
     FROM dw.DimAccount) AS DWAccounts;


SELECT
    (SELECT COUNT(*)
     FROM BrokerageDB.staging.Instrument) AS StagingInstruments,

    (SELECT COUNT(*)
     FROM dw.DimInstrument) AS DWInstruments;

     SELECT
    CustomerKey,
    CustomerId,
    FullName,
    Email,
    CustomerStatus
FROM dw.DimCustomer
ORDER BY CustomerKey;


SELECT
    InstrumentKey,
    InstrumentId,
    Symbol,
    InstrumentName,
    InstrumentType,
    InstrumentCurrency,
    MarketCode,
    MarketName,
    MarketCountryCode,
    MarketCurrency
FROM dw.DimInstrument
ORDER BY InstrumentKey;

SELECT
    CustomerId,
    COUNT(*) AS DuplicateCount
FROM dw.DimCustomer
GROUP BY CustomerId
HAVING COUNT(*) > 1;


SELECT
    AccountId,
    COUNT(*) AS DuplicateCount
FROM dw.DimAccount
GROUP BY AccountId
HAVING COUNT(*) > 1;


SELECT
    InstrumentId,
    COUNT(*) AS DuplicateCount
FROM dw.DimInstrument
GROUP BY InstrumentId
HAVING COUNT(*) > 1;
