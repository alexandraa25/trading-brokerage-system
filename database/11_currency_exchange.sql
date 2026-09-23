/* Conversie între conturi de numerar, la ultimul curs BCE disponibil. */
IF OBJECT_ID('trading.CurrencyConversion', 'U') IS NULL
BEGIN
    CREATE TABLE trading.CurrencyConversion
    (
        CurrencyConversionId BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_CurrencyConversion PRIMARY KEY,
        SourceCashAccountId BIGINT NOT NULL
            CONSTRAINT FK_CurrencyConversion_SourceCashAccount
            FOREIGN KEY REFERENCES core.CashAccount(CashAccountId),
        TargetCashAccountId BIGINT NOT NULL
            CONSTRAINT FK_CurrencyConversion_TargetCashAccount
            FOREIGN KEY REFERENCES core.CashAccount(CashAccountId),
        SourceCurrency CHAR(3) NOT NULL,
        TargetCurrency CHAR(3) NOT NULL,
        SourceAmount DECIMAL(19,4) NOT NULL,
        TargetAmount DECIMAL(19,4) NOT NULL,
        ExchangeRate DECIMAL(19,10) NOT NULL,
        SourceRateToEur DECIMAL(19,10) NOT NULL,
        TargetRateToEur DECIMAL(19,10) NOT NULL,
        SourceRateDate DATE NOT NULL,
        TargetRateDate DATE NOT NULL,
        RateSource VARCHAR(50) NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL
            CONSTRAINT DF_CurrencyConversion_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT CK_CurrencyConversion_Amounts CHECK (SourceAmount > 0 AND TargetAmount > 0),
        CONSTRAINT CK_CurrencyConversion_Accounts CHECK (SourceCashAccountId <> TargetCashAccountId),
        CONSTRAINT CK_CurrencyConversion_Currencies CHECK (SourceCurrency <> TargetCurrency)
    );
END;
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_CashTransaction_Type')
    ALTER TABLE trading.CashTransaction DROP CONSTRAINT CK_CashTransaction_Type;
GO
ALTER TABLE trading.CashTransaction WITH CHECK ADD CONSTRAINT CK_CashTransaction_Type
CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Trade', 'Commission', 'Adjustment', 'CurrencyExchangeOut', 'CurrencyExchangeIn'));
GO

CREATE OR ALTER PROCEDURE trading.usp_ConvertCash
    @SourceCashAccountId BIGINT,
    @TargetCashAccountId BIGINT,
    @SourceAmount DECIMAL(19,4)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SourceCurrency CHAR(3), @TargetCurrency CHAR(3), @CustomerId BIGINT;
    DECLARE @SourceRate DECIMAL(19,10), @TargetRate DECIMAL(19,10);
    DECLARE @SourceRateDate DATE, @TargetRateDate DATE, @TargetAmount DECIMAL(19,4);
    DECLARE @ConversionId BIGINT;

    IF @SourceAmount <= 0
        THROW 50021, N'Suma pentru schimb valutar trebuie să fie mai mare decât zero.', 1;
    IF @SourceCashAccountId = @TargetCashAccountId
        THROW 50022, N'Alege două conturi de numerar diferite.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @SourceCurrency = cash.Currency, @CustomerId = account.CustomerId
        FROM core.CashAccount cash WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN core.Account account WITH (UPDLOCK, HOLDLOCK) ON account.AccountId = cash.AccountId
        INNER JOIN core.Customer customer WITH (UPDLOCK, HOLDLOCK) ON customer.CustomerId = account.CustomerId
        INNER JOIN core.KYC kyc WITH (UPDLOCK, HOLDLOCK) ON kyc.CustomerId = customer.CustomerId
        WHERE cash.CashAccountId = @SourceCashAccountId
          AND cash.AvailableBalance >= @SourceAmount
          AND account.Status = 'Active' AND customer.Status = 'Active' AND kyc.Status = 'Approved';

        SELECT @TargetCurrency = cash.Currency
        FROM core.CashAccount cash WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN core.Account account WITH (UPDLOCK, HOLDLOCK) ON account.AccountId = cash.AccountId
        WHERE cash.CashAccountId = @TargetCashAccountId AND account.CustomerId = @CustomerId AND account.Status = 'Active';

        IF @SourceCurrency IS NULL OR @TargetCurrency IS NULL
            THROW 50023, N'Conturile selectate nu sunt eligibile sau soldul disponibil este insuficient.', 1;
        IF @SourceCurrency = @TargetCurrency
            THROW 50024, N'Conturile selectate trebuie să aibă monede diferite.', 1;

        SELECT TOP 1 @SourceRate = MidRate, @SourceRateDate = RateDate
        FROM core.ExchangeRate WHERE SourceCurrency = @SourceCurrency AND TargetCurrency = 'EUR'
        ORDER BY RateDate DESC;
        SELECT TOP 1 @TargetRate = MidRate, @TargetRateDate = RateDate
        FROM core.ExchangeRate WHERE SourceCurrency = @TargetCurrency AND TargetCurrency = 'EUR'
        ORDER BY RateDate DESC;

        IF @SourceCurrency = 'EUR' BEGIN SET @SourceRate = 1; SET @SourceRateDate = CAST(SYSUTCDATETIME() AS DATE); END;
        IF @TargetCurrency = 'EUR' BEGIN SET @TargetRate = 1; SET @TargetRateDate = CAST(SYSUTCDATETIME() AS DATE); END;
        IF @SourceRate IS NULL OR @TargetRate IS NULL
            THROW 50025, N'Nu există curs BCE disponibil pentru una dintre monede.', 1;

        SET @TargetAmount = ROUND(@SourceAmount * @SourceRate / @TargetRate, 4);

        UPDATE core.CashAccount SET AvailableBalance = AvailableBalance - @SourceAmount WHERE CashAccountId = @SourceCashAccountId;
        UPDATE core.CashAccount SET AvailableBalance = AvailableBalance + @TargetAmount WHERE CashAccountId = @TargetCashAccountId;

        INSERT INTO trading.CurrencyConversion
            (SourceCashAccountId, TargetCashAccountId, SourceCurrency, TargetCurrency, SourceAmount, TargetAmount,
             ExchangeRate, SourceRateToEur, TargetRateToEur, SourceRateDate, TargetRateDate, RateSource)
        VALUES
            (@SourceCashAccountId, @TargetCashAccountId, @SourceCurrency, @TargetCurrency, @SourceAmount, @TargetAmount,
             @SourceRate / @TargetRate, @SourceRate, @TargetRate, @SourceRateDate, @TargetRateDate, 'ECB_REFERENCE');
        SET @ConversionId = SCOPE_IDENTITY();

        INSERT INTO trading.CashTransaction (CashAccountId, TransactionType, Amount, Currency, ReferenceType, ReferenceId, Description)
        VALUES (@SourceCashAccountId, 'CurrencyExchangeOut', -@SourceAmount, @SourceCurrency, 'CurrencyConversion', @ConversionId,
                CONCAT('Schimb valutar către ', @TargetCurrency));
        INSERT INTO trading.CashTransaction (CashAccountId, TransactionType, Amount, Currency, ReferenceType, ReferenceId, Description)
        VALUES (@TargetCashAccountId, 'CurrencyExchangeIn', @TargetAmount, @TargetCurrency, 'CurrencyConversion', @ConversionId,
                CONCAT('Schimb valutar din ', @SourceCurrency));

        COMMIT TRANSACTION;
        SELECT @ConversionId AS CurrencyConversionId, @SourceCurrency AS SourceCurrency, @TargetCurrency AS TargetCurrency,
               @SourceAmount AS SourceAmount, @TargetAmount AS TargetAmount, @SourceRate / @TargetRate AS ExchangeRate,
               @SourceRateDate AS SourceRateDate, @TargetRateDate AS TargetRateDate, 'ECB_REFERENCE' AS RateSource;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
