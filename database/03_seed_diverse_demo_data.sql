USE BrokerageDB;
GO

/*
Set extins și repetabil de date demonstrative.

Prefixurile DEMO și demo.seed permit identificarea clară a datelor generate.
Scriptul nu inserează din nou datele dacă setul există deja.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS
(
    SELECT 1
    FROM core.Customer
    WHERE Email = 'demo.seed.001@example.test'
)
BEGIN
    PRINT N'Setul extins de date există deja. Nu s-au inserat duplicate.';
    RETURN;
END;

BEGIN TRY
    BEGIN TRANSACTION;

    /* Piețe suplimentare */
    INSERT INTO trading.Market
        (MarketCode, MarketName, CountryCode, Currency)
    SELECT source.MarketCode, source.MarketName, source.CountryCode, source.Currency
    FROM
    (
        VALUES
            ('XETR', 'Deutsche Boerse Xetra', 'DE', 'EUR'),
            ('XPAR', 'Euronext Paris', 'FR', 'EUR'),
            ('XBSE', 'Bucharest Stock Exchange', 'RO', 'RON'),
            ('XTSE', 'Toronto Stock Exchange', 'CA', 'CAD'),
            ('XJPX', 'Japan Exchange Group', 'JP', 'JPY')
    ) source(MarketCode, MarketName, CountryCode, Currency)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM trading.Market target
        WHERE target.MarketCode = source.MarketCode
    );

    /* Emitenți din industrii și țări diferite */
    INSERT INTO trading.Issuer
        (IssuerCode, IssuerName, CountryCode)
    SELECT source.IssuerCode, source.IssuerName, source.CountryCode
    FROM
    (
        VALUES
            ('DEMO001', 'Northstar Software', 'US'),
            ('DEMO002', 'Atlantic Healthcare', 'US'),
            ('DEMO003', 'Green Horizon Energy', 'US'),
            ('DEMO004', 'Europa Mobility', 'DE'),
            ('DEMO005', 'Rhine Industrial Group', 'DE'),
            ('DEMO006', 'Paris Consumer Brands', 'FR'),
            ('DEMO007', 'Danube Bank', 'RO'),
            ('DEMO008', 'Carpathian Utilities', 'RO'),
            ('DEMO009', 'Maple Technology', 'CA'),
            ('DEMO010', 'Northern Rail', 'CA'),
            ('DEMO011', 'Sakura Robotics', 'JP'),
            ('DEMO012', 'Pacific Electronics', 'JP'),
            ('DEMO013', 'Global Equity Fund', 'US'),
            ('DEMO014', 'European Bond Fund', 'DE'),
            ('DEMO015', 'Romanian Index Fund', 'RO'),
            ('DEMO016', 'Canadian Dividend Fund', 'CA'),
            ('DEMO017', 'Japan Growth Fund', 'JP'),
            ('DEMO018', 'Sustainable World Fund', 'FR')
    ) source(IssuerCode, IssuerName, CountryCode)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM trading.Issuer target
        WHERE target.IssuerCode = source.IssuerCode
    );

    /* Acțiuni, ETF-uri și obligațiuni în șase valute */
    INSERT INTO trading.Instrument
    (
        MarketId, IssuerId, Symbol, InstrumentName,
        InstrumentType, Currency, IsActive
    )
    SELECT market.MarketId, issuer.IssuerId, source.Symbol,
           source.InstrumentName, source.InstrumentType,
           source.Currency, 1
    FROM
    (
        VALUES
            ('XNAS', 'DEMO001', 'DUSD1', 'Northstar Software',       'Stock', 'USD'),
            ('XNYS', 'DEMO002', 'DUSD2', 'Atlantic Healthcare',     'Stock', 'USD'),
            ('XNAS', 'DEMO013', 'DUSDE', 'Global Equity ETF',       'ETF',   'USD'),
            ('XETR', 'DEMO004', 'DEUR1', 'Europa Mobility',         'Stock', 'EUR'),
            ('XETR', 'DEMO005', 'DEUR2', 'Rhine Industrial Group',  'Stock', 'EUR'),
            ('XPAR', 'DEMO014', 'DEURB', 'European Bond Fund',      'Bond',  'EUR'),
            ('XLON', 'DEMO018', 'DGBP1', 'Sustainable World Fund',  'ETF',   'GBP'),
            ('XLON', 'DEMO006', 'DGBP2', 'Paris Consumer Brands',   'Stock', 'GBP'),
            ('XLON', 'DEMO014', 'DGBPB', 'Sterling Bond Fund',      'Bond',  'GBP'),
            ('XBSE', 'DEMO007', 'DRON1', 'Danube Bank',             'Stock', 'RON'),
            ('XBSE', 'DEMO008', 'DRON2', 'Carpathian Utilities',    'Stock', 'RON'),
            ('XBSE', 'DEMO015', 'DRONE', 'Romanian Index ETF',      'ETF',   'RON'),
            ('XTSE', 'DEMO009', 'DCAD1', 'Maple Technology',        'Stock', 'CAD'),
            ('XTSE', 'DEMO010', 'DCAD2', 'Northern Rail',           'Stock', 'CAD'),
            ('XTSE', 'DEMO016', 'DCADE', 'Canadian Dividend ETF',   'ETF',   'CAD'),
            ('XJPX', 'DEMO011', 'DJPY1', 'Sakura Robotics',         'Stock', 'JPY'),
            ('XJPX', 'DEMO012', 'DJPY2', 'Pacific Electronics',     'Stock', 'JPY'),
            ('XJPX', 'DEMO017', 'DJPYE', 'Japan Growth ETF',        'ETF',   'JPY')
    ) source(MarketCode, IssuerCode, Symbol, InstrumentName, InstrumentType, Currency)
    INNER JOIN trading.Market market
        ON market.MarketCode = source.MarketCode
    INNER JOIN trading.Issuer issuer
        ON issuer.IssuerCode = source.IssuerCode
    WHERE NOT EXISTS
    (
        SELECT 1 FROM trading.Instrument target
        WHERE target.MarketId = market.MarketId
          AND target.Symbol = source.Symbol
    );

    /* 100 de clienți cu tipuri, stări și date demografice variate */
    ;WITH numbers AS
    (
        SELECT 1 AS n
        UNION ALL
        SELECT n + 1 FROM numbers WHERE n < 100
    )
    INSERT INTO core.Customer
    (
        CustomerTypeId, FirstName, LastName, Email, Phone,
        DateOfBirth, Status, CreatedAt, UpdatedAt
    )
    SELECT
        CASE
            WHEN n % 20 = 0 THEN (SELECT CustomerTypeId FROM core.CustomerType WHERE TypeCode = 'INSTITUTIONAL')
            WHEN n % 10 = 0 THEN (SELECT CustomerTypeId FROM core.CustomerType WHERE TypeCode = 'CORPORATE')
            ELSE (SELECT CustomerTypeId FROM core.CustomerType WHERE TypeCode = 'INDIVIDUAL')
        END,
        CHOOSE(((n - 1) % 15) + 1,
            'Ana', 'Mihai', 'Elena', 'Andrei', 'Sofia',
            'David', 'Maria', 'Alex', 'Ioana', 'Victor',
            'Emma', 'Luca', 'Nora', 'Matei', 'Daria'),
        CHOOSE(((n * 7 - 1) % 15) + 1,
            'Popescu', 'Ionescu', 'Marin', 'Dumitru', 'Stan',
            'Georgescu', 'Radu', 'Petrescu', 'Munteanu', 'Ilie',
            'Weber', 'Martin', 'Tanaka', 'Wilson', 'Dubois'),
        CONCAT('demo.seed.', RIGHT(CONCAT('000', n), 3), '@example.test'),
        CONCAT('+40-700-', RIGHT(CONCAT('000000', 100000 + n), 6)),
        DATEADD(DAY, -(7000 + n * 97), CAST('2026-01-01' AS DATE)),
        CASE WHEN n <= 85 THEN 'Active'
             WHEN n <= 93 THEN 'Inactive'
             ELSE 'Blocked' END,
        DATEADD(DAY, -(30 + n * 5), SYSUTCDATETIME()),
        DATEADD(DAY, -(n % 20), SYSUTCDATETIME())
    FROM numbers
    OPTION (MAXRECURSION 100);

    /* KYC: aprobat, în așteptare, respins, expirat și cinci clienți fără KYC */
    ;WITH demo_customers AS
    (
        SELECT CustomerId,
               ROW_NUMBER() OVER (ORDER BY CustomerId) AS n
        FROM core.Customer
        WHERE Email LIKE 'demo.seed.%@example.test'
    )
    INSERT INTO core.KYC
    (
        CustomerId, Status, DocumentType, VerifiedAt,
        VerifiedBy, RejectionReason, CreatedAt, UpdatedAt
    )
    SELECT
        CustomerId,
        CASE WHEN n <= 80 THEN 'Approved'
             WHEN n <= 87 THEN 'Pending'
             WHEN n <= 92 THEN 'Rejected'
             ELSE 'Expired' END,
        CHOOSE(((n - 1) % 4) + 1,
            'IdentityCard', 'Passport', 'CompanyRegistry', 'ResidencePermit'),
        CASE WHEN n <= 80 THEN DATEADD(DAY, -(n % 120), SYSUTCDATETIME()) END,
        CASE WHEN n <= 80 THEN 'demo-kyc-team' END,
        CASE WHEN n BETWEEN 88 AND 92 THEN
            CHOOSE(((n - 88) % 3) + 1,
                'Document expirat', 'Date neconcordante', 'Document neclar')
        END,
        DATEADD(DAY, -(25 + n * 3), SYSUTCDATETIME()),
        DATEADD(DAY, -(n % 15), SYSUTCDATETIME())
    FROM demo_customers
    WHERE n <= 95;

    /* Câte un cont principal pentru fiecare client */
    ;WITH demo_customers AS
    (
        SELECT CustomerId,
               ROW_NUMBER() OVER (ORDER BY CustomerId) AS n
        FROM core.Customer
        WHERE Email LIKE 'demo.seed.%@example.test'
    )
    INSERT INTO core.Account
        (CustomerId, AccountNumber, Currency, Status, CreatedAt, ClosedAt)
    SELECT
        CustomerId,
        CONCAT('DEMO-', RIGHT(CONCAT('0000', n), 4)),
        CHOOSE(((n - 1) % 6) + 1, 'USD', 'EUR', 'GBP', 'RON', 'CAD', 'JPY'),
        CASE WHEN n <= 85 THEN 'Active'
             WHEN n <= 90 THEN 'Pending'
             WHEN n <= 96 THEN 'Suspended'
             ELSE 'Closed' END,
        DATEADD(DAY, -(20 + n * 4), SYSUTCDATETIME()),
        CASE WHEN n > 96 THEN DATEADD(DAY, -(n - 96), SYSUTCDATETIME()) END
    FROM demo_customers;

    /* Conturi de numerar și depuneri inițiale */
    INSERT INTO core.CashAccount
        (AccountId, Currency, AvailableBalance, BlockedBalance, CreatedAt)
    SELECT
        account.AccountId,
        account.Currency,
        CAST(100000 + sequence.n * 2500 AS DECIMAL(19,4)),
        CAST(CASE WHEN sequence.n % 9 = 0 THEN 500 ELSE 0 END AS DECIMAL(19,4)),
        account.CreatedAt
    FROM core.Account account
    CROSS APPLY
    (
        SELECT CONVERT(INT, RIGHT(account.AccountNumber, 4)) AS n
    ) sequence
    WHERE account.AccountNumber LIKE 'DEMO-%';

    INSERT INTO trading.CashTransaction
    (
        CashAccountId, TransactionType, Amount, Currency,
        ReferenceType, Description, CreatedAt
    )
    SELECT
        cash.CashAccountId,
        'Deposit',
        cash.AvailableBalance,
        cash.Currency,
        'DemoSeed',
        'Capital inițial pentru setul demonstrativ',
        cash.CreatedAt
    FROM core.CashAccount cash
    INNER JOIN core.Account account ON account.AccountId = cash.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    /* Ordine executate integral, parțial, în așteptare, anulate și respinse */
    DECLARE
        @AccountId BIGINT,
        @InstrumentId BIGINT,
        @Sequence INT,
        @OrderId BIGINT,
        @Quantity DECIMAL(19,8),
        @FirstFill DECIMAL(19,8),
        @RemainingFill DECIMAL(19,8),
        @ExecutionPrice DECIMAL(19,8),
        @Price DECIMAL(19,8);

    DECLARE @ExecutionResult TABLE
    (
        OrderId BIGINT,
        ExecutionId BIGINT,
        ExecutedQuantity DECIMAL(19,8),
        ExecutionPrice DECIMAL(19,8),
        TradeValue DECIMAL(19,4),
        CommissionAmount DECIMAL(19,4),
        Currency CHAR(3),
        NewOrderStatus VARCHAR(20)
    );

    DECLARE eligible_accounts CURSOR LOCAL FAST_FORWARD FOR
        SELECT account.AccountId, instrument.InstrumentId,
               CONVERT(INT, RIGHT(account.AccountNumber, 4)) AS SequenceNumber
        FROM core.Account account
        INNER JOIN core.Customer customer ON customer.CustomerId = account.CustomerId
        INNER JOIN core.KYC kyc ON kyc.CustomerId = customer.CustomerId
        CROSS APPLY
        (
            SELECT TOP (1) i.InstrumentId
            FROM trading.Instrument i
            WHERE i.Currency = account.Currency
              AND i.IsActive = 1
              AND i.Symbol LIKE 'D%'
            ORDER BY i.InstrumentId
        ) instrument
        WHERE account.AccountNumber LIKE 'DEMO-%'
          AND account.Status = 'Active'
          AND customer.Status = 'Active'
          AND kyc.Status = 'Approved'
        ORDER BY account.AccountId;

    OPEN eligible_accounts;
    FETCH NEXT FROM eligible_accounts INTO @AccountId, @InstrumentId, @Sequence;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Price = CAST(25 + (@Sequence % 70) AS DECIMAL(19,8));

        /* BUY executat integral */
        SET @Quantity = 10 + (@Sequence % 20);
        INSERT INTO trading.[Order]
            (AccountId, InstrumentId, Side, OrderType, Quantity, LimitPrice, Status)
        VALUES
            (@AccountId, @InstrumentId, 'BUY', 'LIMIT', @Quantity, @Price + 5, 'Pending');
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO @ExecutionResult
        EXEC trading.usp_ExecuteOrder @OrderId, @Quantity, @Price;
        DELETE FROM @ExecutionResult;

        /* BUY executat în două tranșe */
        SET @Quantity = 20 + (@Sequence % 30);
        SET @FirstFill = FLOOR(@Quantity * 0.4);
        SET @RemainingFill = @Quantity - @FirstFill;
        SET @ExecutionPrice = @Price - 1;
        INSERT INTO trading.[Order]
            (AccountId, InstrumentId, Side, OrderType, Quantity, LimitPrice, Status)
        VALUES
            (@AccountId, @InstrumentId, 'BUY', 'LIMIT', @Quantity, @Price + 4, 'Pending');
        SET @OrderId = SCOPE_IDENTITY();

        INSERT INTO @ExecutionResult
        EXEC trading.usp_ExecuteOrder @OrderId, @FirstFill, @ExecutionPrice;
        DELETE FROM @ExecutionResult;

        INSERT INTO @ExecutionResult
        EXEC trading.usp_ExecuteOrder @OrderId, @RemainingFill, @Price;
        DELETE FROM @ExecutionResult;

        /* Ordine fără execuție, pentru diversitatea stărilor */
        INSERT INTO trading.[Order]
            (AccountId, InstrumentId, Side, OrderType, Quantity, LimitPrice, Status)
        VALUES
            (@AccountId, @InstrumentId, 'BUY', 'MARKET', 5 + (@Sequence % 10), NULL, 'Pending'),
            (@AccountId, @InstrumentId, 'BUY', 'LIMIT',  7 + (@Sequence % 10), @Price - 8, 'Cancelled'),
            (@AccountId, @InstrumentId, 'BUY', 'LIMIT',  3 + (@Sequence % 8),  @Price - 15, 'Rejected');

        /* SELL executat pentru jumătate dintre conturile eligibile */
        IF @Sequence % 2 = 0
        BEGIN
            INSERT INTO trading.[Order]
                (AccountId, InstrumentId, Side, OrderType, Quantity, LimitPrice, Status)
            VALUES
                (@AccountId, @InstrumentId, 'SELL', 'LIMIT', 5, @Price - 2, 'Pending');
            SET @OrderId = SCOPE_IDENTITY();

            INSERT INTO @ExecutionResult
            EXEC trading.usp_ExecuteOrder @OrderId, 5, @Price;
            DELETE FROM @ExecutionResult;
        END;

        FETCH NEXT FROM eligible_accounts INTO @AccountId, @InstrumentId, @Sequence;
    END;

    CLOSE eligible_accounts;
    DEALLOCATE eligible_accounts;

    /* Distribuie activitatea pe ultimele 18 luni pentru rapoarte mai utile */
    UPDATE execution_row
    SET ExecutedAt = DATEADD(HOUR, order_row.OrderId % 20, order_row.CreatedAt),
        CreatedAt = DATEADD(HOUR, order_row.OrderId % 20, order_row.CreatedAt)
    FROM trading.Execution execution_row
    INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
    INNER JOIN core.Account account ON account.AccountId = order_row.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    UPDATE order_row
    SET CreatedAt = DATEADD(DAY, -(order_row.OrderId % 540), SYSUTCDATETIME()),
        UpdatedAt = CASE WHEN order_row.Status IN ('Executed', 'Cancelled', 'Rejected')
                         THEN DATEADD(DAY, -(order_row.OrderId % 540) + 1, SYSUTCDATETIME())
                         ELSE DATEADD(DAY, -(order_row.OrderId % 540), SYSUTCDATETIME()) END
    FROM trading.[Order] order_row
    INNER JOIN core.Account account ON account.AccountId = order_row.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    UPDATE execution_row
    SET ExecutedAt = DATEADD(HOUR, execution_row.ExecutionId % 20, order_row.CreatedAt),
        CreatedAt = DATEADD(HOUR, execution_row.ExecutionId % 20, order_row.CreatedAt)
    FROM trading.Execution execution_row
    INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
    INNER JOIN core.Account account ON account.AccountId = order_row.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    UPDATE commission
    SET CreatedAt = execution_row.ExecutedAt
    FROM trading.Commission commission
    INNER JOIN trading.Execution execution_row
        ON execution_row.ExecutionId = commission.ExecutionId
    INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
    INNER JOIN core.Account account ON account.AccountId = order_row.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    UPDATE cash_transaction
    SET CreatedAt = execution_row.ExecutedAt
    FROM trading.CashTransaction cash_transaction
    INNER JOIN trading.Execution execution_row
        ON cash_transaction.ReferenceType = 'Execution'
       AND cash_transaction.ReferenceId = execution_row.ExecutionId
    INNER JOIN trading.[Order] order_row ON order_row.OrderId = execution_row.OrderId
    INNER JOIN core.Account account ON account.AccountId = order_row.AccountId
    WHERE account.AccountNumber LIKE 'DEMO-%';

    COMMIT TRANSACTION;

    PRINT N'Setul extins de date demonstrative a fost inserat cu succes.';
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'eligible_accounts') >= 0
        CLOSE eligible_accounts;
    IF CURSOR_STATUS('local', 'eligible_accounts') > -3
        DEALLOCATE eligible_accounts;
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Rezumatul setului demonstrativ */
SELECT 'Customer' AS EntityName, COUNT(*) AS TotalRows
FROM core.Customer WHERE Email LIKE 'demo.seed.%@example.test'
UNION ALL
SELECT 'Account', COUNT(*) FROM core.Account WHERE AccountNumber LIKE 'DEMO-%'
UNION ALL
SELECT 'Instrument', COUNT(*)
FROM trading.Instrument instrument
INNER JOIN trading.Issuer issuer ON issuer.IssuerId = instrument.IssuerId
WHERE issuer.IssuerCode LIKE 'DEMO%'
UNION ALL
SELECT 'Order', COUNT(*)
FROM trading.[Order] o
INNER JOIN core.Account a ON a.AccountId = o.AccountId
WHERE a.AccountNumber LIKE 'DEMO-%'
UNION ALL
SELECT 'Execution', COUNT(*)
FROM trading.Execution e
INNER JOIN trading.[Order] o ON o.OrderId = e.OrderId
INNER JOIN core.Account a ON a.AccountId = o.AccountId
WHERE a.AccountNumber LIKE 'DEMO-%';
GO
