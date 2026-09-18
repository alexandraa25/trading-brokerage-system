USE BrokerageDB;
GO

CREATE OR ALTER PROCEDURE trading.usp_CreateOrder
    @AccountId BIGINT,
    @InstrumentId BIGINT,
    @Side VARCHAR(4),
    @OrderType VARCHAR(10),
    @Quantity DECIMAL(19,8),
    @LimitPrice DECIMAL(19,8) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @Currency CHAR(3),
        @OrderId BIGINT,
        @RequiredCash DECIMAL(19,4);

    IF @Side NOT IN ('BUY', 'SELL')
        THROW 50030, N'Direcția ordinului trebuie să fie BUY sau SELL.', 1;

    IF @OrderType NOT IN ('MARKET', 'LIMIT')
        THROW 50031, N'Tipul ordinului trebuie să fie MARKET sau LIMIT.', 1;

    IF @Quantity <= 0
        THROW 50032, N'Cantitatea ordinului trebuie să fie mai mare decât zero.', 1;

    IF (@OrderType = 'MARKET' AND @LimitPrice IS NOT NULL)
       OR (@OrderType = 'LIMIT' AND (@LimitPrice IS NULL OR @LimitPrice <= 0))
        THROW 50033, N'Prețul limită nu este valid pentru tipul de ordin selectat.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM core.Account a WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN core.Customer c WITH (UPDLOCK, HOLDLOCK)
                ON c.CustomerId = a.CustomerId
            INNER JOIN core.KYC k WITH (UPDLOCK, HOLDLOCK)
                ON k.CustomerId = c.CustomerId
            WHERE a.AccountId = @AccountId
              AND a.Status = 'Active'
              AND c.Status = 'Active'
              AND k.Status = 'Approved'
        )
            THROW 50034, N'Starea contului, a clientului sau a verificării KYC nu permite tranzacționarea.', 1;

        SELECT @Currency = Currency
        FROM trading.Instrument WITH (HOLDLOCK)
        WHERE InstrumentId = @InstrumentId
          AND IsActive = 1;

        IF @Currency IS NULL
            THROW 50035, N'Instrumentul nu există sau este inactiv.', 1;

        IF NOT EXISTS
        (
            SELECT 1
            FROM core.CashAccount WITH (UPDLOCK, HOLDLOCK)
            WHERE AccountId = @AccountId
              AND Currency = @Currency
        )
            THROW 50036, N'Este necesar un cont de numerar în valuta instrumentului.', 1;

        IF @Side = 'BUY' AND @OrderType = 'LIMIT'
        BEGIN
            SET @RequiredCash = ROUND(@Quantity * @LimitPrice * 1.0025, 4);

            IF NOT EXISTS
            (
                SELECT 1
                FROM core.CashAccount
                WHERE AccountId = @AccountId
                  AND Currency = @Currency
                  AND AvailableBalance >= @RequiredCash
            )
                THROW 50037, N'Numerar insuficient pentru ordinul limită.', 1;
        END;

        IF @Side = 'SELL'
           AND NOT EXISTS
           (
               SELECT 1
               FROM trading.Position WITH (UPDLOCK, HOLDLOCK)
               WHERE AccountId = @AccountId
                 AND InstrumentId = @InstrumentId
                 AND Quantity >= @Quantity
           )
            THROW 50038, N'Cantitate insuficientă în poziție pentru ordinul de vânzare.', 1;

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
            @AccountId,
            @InstrumentId,
            @Side,
            @OrderType,
            @Quantity,
            @LimitPrice,
            'Pending'
        );

        SET @OrderId = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT @OrderId AS OrderId, 'Pending' AS Status;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
