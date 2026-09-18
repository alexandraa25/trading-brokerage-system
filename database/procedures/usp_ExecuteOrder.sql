USE BrokerageDB;
GO

CREATE OR ALTER PROCEDURE trading.usp_ExecuteOrder
    @OrderId BIGINT,
    @ExecutedQuantity DECIMAL(19,8),
    @ExecutionPrice DECIMAL(19,8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @AccountId BIGINT,
        @InstrumentId BIGINT,
        @Side VARCHAR(4),
        @OrderStatus VARCHAR(20),
        @AccountStatus VARCHAR(20),
        @CustomerStatus VARCHAR(20),
        @KycStatus VARCHAR(20),
        @OrderQuantity DECIMAL(19,8),
        @LimitPrice DECIMAL(19,8),
        @Currency CHAR(3),
        @CashAccountId BIGINT,
        @TradeValue DECIMAL(19,4),
        @CommissionAmount DECIMAL(19,4),
        @TotalCashRequired DECIMAL(19,4),
        @ExecutionId BIGINT,
        @ExecutedSoFar DECIMAL(19,8),
        @RemainingQuantity DECIMAL(19,8);

    BEGIN TRY

        ------------------------------------------------
        -- 1. Validarea datelor de intrare
        ------------------------------------------------

        IF @ExecutedQuantity <= 0
        BEGIN
            THROW 50010, N'Cantitatea executată trebuie să fie mai mare decât zero.', 1;
        END;

        IF @ExecutionPrice <= 0
        BEGIN
            THROW 50011, N'Prețul de execuție trebuie să fie mai mare decât zero.', 1;
        END;


        ------------------------------------------------
        -- 2. Începe tranzacția ÎNAINTE de citirea stării
        ------------------------------------------------

        BEGIN TRANSACTION;


        ------------------------------------------------
        -- 3. Blochează ordinul
        ------------------------------------------------

        SELECT
            @AccountId = o.AccountId,
            @InstrumentId = o.InstrumentId,
            @Side = o.Side,
            @OrderStatus = o.Status,
            @OrderQuantity = o.Quantity,
            @LimitPrice = o.LimitPrice
        FROM trading.[Order] o WITH (UPDLOCK, HOLDLOCK)
        WHERE o.OrderId = @OrderId;


        ------------------------------------------------
        -- 4. Ordinul există?
        ------------------------------------------------

        IF @AccountId IS NULL
        BEGIN
            THROW 50012, N'Ordinul nu există.', 1;
        END;


        ------------------------------------------------
        -- 5. Verifică starea
        ------------------------------------------------

        IF @OrderStatus NOT IN
        (
            'Pending',
            'PartiallyExecuted'
        )
        BEGIN
            THROW 50013, N'Ordinul nu poate fi executat în starea curentă.', 1;
        END;

        SELECT
            @AccountStatus = a.Status,
            @CustomerStatus = c.Status,
            @KycStatus = k.Status
        FROM core.Account a WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN core.Customer c WITH (UPDLOCK, HOLDLOCK)
            ON c.CustomerId = a.CustomerId
        LEFT JOIN core.KYC k WITH (UPDLOCK, HOLDLOCK)
            ON k.CustomerId = c.CustomerId
        WHERE a.AccountId = @AccountId;

        IF @AccountStatus <> 'Active'
            THROW 50020, N'Contul de tranzacționare nu este activ.', 1;

        IF @CustomerStatus <> 'Active'
            THROW 50021, N'Clientul nu este activ.', 1;

        IF ISNULL(@KycStatus, '') <> 'Approved'
            THROW 50022, N'Verificarea KYC a clientului nu este aprobată.', 1;


        ------------------------------------------------
        -- 6. Ce cantitate a fost deja executată?
        ------------------------------------------------

        SELECT
            @ExecutedSoFar =
                ISNULL(SUM(ExecutedQuantity), 0)
        FROM trading.Execution WITH (HOLDLOCK)
        WHERE OrderId = @OrderId;


        SET @RemainingQuantity =
            @OrderQuantity - @ExecutedSoFar;


        ------------------------------------------------
        -- 7. Nu se poate executa mai mult decât cantitatea rămasă
        ------------------------------------------------

        IF @ExecutedQuantity > @RemainingQuantity
        BEGIN
            THROW 50014, N'Cantitatea executată depășește cantitatea rămasă din ordin.', 1;
        END;


        ------------------------------------------------
        -- 8. Validarea ordinului limită
        ------------------------------------------------

        IF @Side = 'BUY'
           AND @LimitPrice IS NOT NULL
           AND @ExecutionPrice > @LimitPrice
        BEGIN
            THROW 50015, N'Prețul de execuție depășește prețul limită BUY.', 1;
        END;


        IF @Side = 'SELL'
           AND @LimitPrice IS NOT NULL
           AND @ExecutionPrice < @LimitPrice
        BEGIN
            THROW 50016, N'Prețul de execuție este sub prețul limită SELL.', 1;
        END;


        ------------------------------------------------
        -- 9. Valuta instrumentului
        ------------------------------------------------

        SELECT
            @Currency = i.Currency
        FROM trading.Instrument i
        WHERE i.InstrumentId = @InstrumentId;


        ------------------------------------------------
        -- 10. Contul de numerar
        ------------------------------------------------

        SELECT
            @CashAccountId = ca.CashAccountId
        FROM core.CashAccount ca WITH (UPDLOCK, HOLDLOCK)
        WHERE ca.AccountId = @AccountId
          AND ca.Currency = @Currency;


        IF @CashAccountId IS NULL
        BEGIN
            THROW 50017, N'Nu există un cont de numerar corespunzător.', 1;
        END;


        ------------------------------------------------
        -- 11. Valoarea tranzacției
        ------------------------------------------------

        SET @TradeValue =
            ROUND(@ExecutedQuantity * @ExecutionPrice, 4);


        ------------------------------------------------
        -- 12. Comision
        ------------------------------------------------

        SET @CommissionAmount =
            ROUND(@TradeValue * 0.0025, 4);


        ------------------------------------------------
        -- 13. Validarea numerarului pentru cumpărare
        ------------------------------------------------

        IF @Side = 'BUY'
        BEGIN

            SET @TotalCashRequired =
                @TradeValue + @CommissionAmount;

            IF
            (
                SELECT AvailableBalance
                FROM core.CashAccount
                WHERE CashAccountId = @CashAccountId
            ) < @TotalCashRequired
            BEGIN
                THROW 50018, N'Sold de numerar insuficient.', 1;
            END;

        END;


        ------------------------------------------------
        -- 14. Validarea poziției pentru vânzare
        ------------------------------------------------

        IF @Side = 'SELL'
        BEGIN

            IF NOT EXISTS
            (
                SELECT 1
                FROM trading.Position WITH (UPDLOCK, HOLDLOCK)
                WHERE AccountId = @AccountId
                  AND InstrumentId = @InstrumentId
                  AND Quantity >= @ExecutedQuantity
            )
            BEGIN
                THROW 50019, N'Cantitate insuficientă în poziție.', 1;
            END;

        END;


        ------------------------------------------------
        -- 15. Creează execuția
        ------------------------------------------------

        INSERT INTO trading.Execution
        (
            OrderId,
            ExecutedQuantity,
            ExecutionPrice,
            ExecutedAt
        )
        VALUES
        (
            @OrderId,
            @ExecutedQuantity,
            @ExecutionPrice,
            SYSUTCDATETIME()
        );

        SET @ExecutionId = SCOPE_IDENTITY();


        ------------------------------------------------
        -- 16. Comision
        ------------------------------------------------

        INSERT INTO trading.Commission
        (
            ExecutionId,
            CommissionType,
            Rate,
            Amount,
            Currency
        )
        VALUES
        (
            @ExecutionId,
            'Percentage',
            0.0025,
            @CommissionAmount,
            @Currency
        );


        ------------------------------------------------
        -- 17. Poziția de cumpărare
        ------------------------------------------------

        IF @Side = 'BUY'
        BEGIN

            IF EXISTS
            (
                SELECT 1
                FROM trading.Position WITH (UPDLOCK, HOLDLOCK)
                WHERE AccountId = @AccountId
                  AND InstrumentId = @InstrumentId
            )
            BEGIN

                UPDATE p
                SET
                    Quantity =
                        p.Quantity + @ExecutedQuantity,

                    AveragePrice =
                        (
                            (p.Quantity * p.AveragePrice)
                            +
                            (@ExecutedQuantity * @ExecutionPrice)
                        )
                        /
                        (p.Quantity + @ExecutedQuantity),

                    UpdatedAt = SYSUTCDATETIME()
                FROM trading.Position p
                WHERE p.AccountId = @AccountId
                  AND p.InstrumentId = @InstrumentId;

            END
            ELSE
            BEGIN

                INSERT INTO trading.Position
                (
                    AccountId,
                    InstrumentId,
                    Quantity,
                    AveragePrice
                )
                VALUES
                (
                    @AccountId,
                    @InstrumentId,
                    @ExecutedQuantity,
                    @ExecutionPrice
                );

            END;

        END;


        ------------------------------------------------
        -- 18. Poziția de vânzare
        ------------------------------------------------

        IF @Side = 'SELL'
        BEGIN

            UPDATE trading.Position
            SET
                Quantity = Quantity - @ExecutedQuantity,
                UpdatedAt = SYSUTCDATETIME()
            WHERE AccountId = @AccountId
              AND InstrumentId = @InstrumentId;

        END;


        ------------------------------------------------
        -- 19. Decontarea numerarului
        ------------------------------------------------

        UPDATE core.CashAccount
        SET
            AvailableBalance =
                CASE
                    WHEN @Side = 'BUY'
                        THEN AvailableBalance
                             - @TradeValue
                             - @CommissionAmount

                    ELSE AvailableBalance
                         + @TradeValue
                         - @CommissionAmount
                END
        WHERE CashAccountId = @CashAccountId;


        ------------------------------------------------
        -- 20. Tranzacția aferentă ordinului
        ------------------------------------------------

        INSERT INTO trading.CashTransaction
        (
            CashAccountId,
            TransactionType,
            Amount,
            Currency,
            ReferenceType,
            ReferenceId,
            Description
        )
        VALUES
        (
            @CashAccountId,
            'Trade',
            CASE
                WHEN @Side = 'BUY'
                    THEN -@TradeValue
                ELSE @TradeValue
            END,
            @Currency,
            'Execution',
            @ExecutionId,
            'Trade settlement'
        );


        ------------------------------------------------
        -- 21. Tranzacția aferentă comisionului
        ------------------------------------------------

        INSERT INTO trading.CashTransaction
        (
            CashAccountId,
            TransactionType,
            Amount,
            Currency,
            ReferenceType,
            ReferenceId,
            Description
        )
        VALUES
        (
            @CashAccountId,
            'Commission',
            -@CommissionAmount,
            @Currency,
            'Execution',
            @ExecutionId,
            'Trading commission'
        );


        ------------------------------------------------
        -- 22. Determină noua stare a ordinului
        ------------------------------------------------

        IF @ExecutedQuantity = @RemainingQuantity
        BEGIN

            UPDATE trading.[Order]
            SET
                Status = 'Executed',
                UpdatedAt = SYSUTCDATETIME()
            WHERE OrderId = @OrderId;

        END
        ELSE
        BEGIN

            UPDATE trading.[Order]
            SET
                Status = 'PartiallyExecuted',
                UpdatedAt = SYSUTCDATETIME()
            WHERE OrderId = @OrderId;

        END;


        ------------------------------------------------
        -- 23. Confirmă tranzacția
        ------------------------------------------------

        COMMIT TRANSACTION;


        ------------------------------------------------
        -- 24. Rezultat
        ------------------------------------------------

        SELECT
            @OrderId AS OrderId,
            @ExecutionId AS ExecutionId,
            @ExecutedQuantity AS ExecutedQuantity,
            @ExecutionPrice AS ExecutionPrice,
            @TradeValue AS TradeValue,
            @CommissionAmount AS CommissionAmount,
            @Currency AS Currency,
            CASE
                WHEN @ExecutedQuantity = @RemainingQuantity
                    THEN 'Executed'
                ELSE 'PartiallyExecuted'
            END AS NewOrderStatus;

    END TRY

    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;

    END CATCH;
END;
GO
