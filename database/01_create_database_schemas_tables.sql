CREATE DATABASE BrokerageDB;
GO

USE BrokerageDB;
GO

CREATE SCHEMA core;
GO

CREATE SCHEMA trading;
GO

CREATE SCHEMA audit;
GO

CREATE TABLE core.CustomerType
(
    CustomerTypeId TINYINT IDENTITY(1,1) NOT NULL,
    TypeCode       VARCHAR(30) NOT NULL,
    TypeName       VARCHAR(100) NOT NULL,
    Description    VARCHAR(500) NULL,
    IsActive       BIT NOT NULL CONSTRAINT DF_CustomerType_IsActive DEFAULT (1),
    CreatedAt      DATETIME2(3) NOT NULL CONSTRAINT DF_CustomerType_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_CustomerType PRIMARY KEY (CustomerTypeId),
    CONSTRAINT UQ_CustomerType_TypeCode UNIQUE (TypeCode)
);
GO

CREATE TABLE core.Customer
(
    CustomerId     BIGINT IDENTITY(1,1) NOT NULL,
    CustomerTypeId TINYINT NOT NULL,
    FirstName      VARCHAR(100) NOT NULL,
    LastName       VARCHAR(100) NOT NULL,
    Email          VARCHAR(255) NOT NULL,
    Phone          VARCHAR(30) NULL,
    DateOfBirth    DATE NULL,
    Status         VARCHAR(20) NOT NULL,
    CreatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_Customer_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_Customer_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId),

    CONSTRAINT FK_Customer_CustomerType
        FOREIGN KEY (CustomerTypeId)
        REFERENCES core.CustomerType(CustomerTypeId),

    CONSTRAINT UQ_Customer_Email UNIQUE (Email),

    CONSTRAINT CK_Customer_Status
        CHECK (Status IN ('Active', 'Inactive', 'Blocked'))
);
GO


CREATE TABLE core.KYC
(
    KycId           BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId      BIGINT NOT NULL,
    Status          VARCHAR(20) NOT NULL,
    DocumentType    VARCHAR(50) NULL,
    VerifiedAt      DATETIME2(3) NULL,
    VerifiedBy      VARCHAR(100) NULL,
    RejectionReason VARCHAR(500) NULL,
    CreatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_KYC_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt       DATETIME2(3) NOT NULL
        CONSTRAINT DF_KYC_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_KYC PRIMARY KEY (KycId),

    CONSTRAINT FK_KYC_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES core.Customer(CustomerId),

    CONSTRAINT UQ_KYC_Customer UNIQUE (CustomerId),

    CONSTRAINT CK_KYC_Status
        CHECK (Status IN ('Pending', 'Approved', 'Rejected', 'Expired'))
);
GO

CREATE TABLE core.Account
(
    AccountId     BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId    BIGINT NOT NULL,
    AccountNumber VARCHAR(30) NOT NULL,
    Currency      CHAR(3) NOT NULL,
    Status        VARCHAR(20) NOT NULL,
    CreatedAt     DATETIME2(3) NOT NULL
        CONSTRAINT DF_Account_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt     DATETIME2(3) NOT NULL
        CONSTRAINT DF_Account_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    ClosedAt      DATETIME2(3) NULL,

    CONSTRAINT PK_Account PRIMARY KEY (AccountId),

    CONSTRAINT FK_Account_Customer
        FOREIGN KEY (CustomerId)
        REFERENCES core.Customer(CustomerId),

    CONSTRAINT UQ_Account_AccountNumber UNIQUE (AccountNumber),

    CONSTRAINT CK_Account_Status
        CHECK (Status IN ('Pending', 'Active', 'Suspended', 'Closed')),

    CONSTRAINT CK_Account_ClosedAt
        CHECK
        (
            (Status = 'Closed' AND ClosedAt IS NOT NULL)
            OR
            (Status <> 'Closed')
        )
);
GO

CREATE TABLE core.CashAccount
(
    CashAccountId    BIGINT IDENTITY(1,1) NOT NULL,
    AccountId        BIGINT NOT NULL,
    Currency         CHAR(3) NOT NULL,
    AvailableBalance DECIMAL(19,4) NOT NULL,
    BlockedBalance   DECIMAL(19,4) NOT NULL,
    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_CashAccount_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_CashAccount PRIMARY KEY (CashAccountId),

    CONSTRAINT FK_CashAccount_Account
        FOREIGN KEY (AccountId)
        REFERENCES core.Account(AccountId),

    CONSTRAINT UQ_CashAccount_Account_Currency
        UNIQUE (AccountId, Currency),

    CONSTRAINT CK_CashAccount_AvailableBalance
        CHECK (AvailableBalance >= 0),

    CONSTRAINT CK_CashAccount_BlockedBalance
        CHECK (BlockedBalance >= 0)
);
GO

CREATE TABLE trading.Market
(
    MarketId    INT IDENTITY(1,1) NOT NULL,
    MarketCode  VARCHAR(20) NOT NULL,
    MarketName  VARCHAR(100) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    Currency    CHAR(3) NOT NULL,
    IsActive    BIT NOT NULL
        CONSTRAINT DF_Market_IsActive DEFAULT (1),
    CreatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Market_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Market_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Market PRIMARY KEY (MarketId),
    CONSTRAINT UQ_Market_MarketCode UNIQUE (MarketCode)
);
GO

CREATE TABLE trading.Issuer
(
    IssuerId    INT IDENTITY(1,1) NOT NULL,
    IssuerCode  VARCHAR(30) NOT NULL,
    IssuerName  VARCHAR(200) NOT NULL,
    CountryCode CHAR(2) NOT NULL,
    IsActive    BIT NOT NULL
        CONSTRAINT DF_Issuer_IsActive DEFAULT (1),
    CreatedAt   DATETIME2(3) NOT NULL
        CONSTRAINT DF_Issuer_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Issuer PRIMARY KEY (IssuerId),
    CONSTRAINT UQ_Issuer_IssuerCode UNIQUE (IssuerCode)
);
GO

CREATE TABLE trading.Instrument
(
    InstrumentId   BIGINT IDENTITY(1,1) NOT NULL,
    MarketId       INT NOT NULL,
    IssuerId       INT NOT NULL,
    Symbol         VARCHAR(20) NOT NULL,
    InstrumentName VARCHAR(200) NOT NULL,
    InstrumentType VARCHAR(20) NOT NULL,
    Currency       CHAR(3) NOT NULL,
    IsActive       BIT NOT NULL
        CONSTRAINT DF_Instrument_IsActive DEFAULT (1),
    CreatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_Instrument_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_Instrument_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Instrument PRIMARY KEY (InstrumentId),

    CONSTRAINT FK_Instrument_Market
        FOREIGN KEY (MarketId)
        REFERENCES trading.Market(MarketId),

    CONSTRAINT FK_Instrument_Issuer
        FOREIGN KEY (IssuerId)
        REFERENCES trading.Issuer(IssuerId),

    CONSTRAINT UQ_Instrument_Market_Symbol
        UNIQUE (MarketId, Symbol),

    CONSTRAINT CK_Instrument_Type
        CHECK (InstrumentType IN ('Stock', 'ETF', 'Bond'))
);
GO

CREATE TABLE trading.[Order]
(
    OrderId      BIGINT IDENTITY(1,1) NOT NULL,
    AccountId    BIGINT NOT NULL,
    InstrumentId BIGINT NOT NULL,
    Side         VARCHAR(4) NOT NULL,
    OrderType    VARCHAR(10) NOT NULL,
    Quantity     DECIMAL(19,8) NOT NULL,
    LimitPrice   DECIMAL(19,8) NULL,
    Status       VARCHAR(20) NOT NULL,
    CreatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_Order_CreatedAt DEFAULT (SYSUTCDATETIME()),
    UpdatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_Order_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Order PRIMARY KEY (OrderId),

    CONSTRAINT FK_Order_Account
        FOREIGN KEY (AccountId)
        REFERENCES core.Account(AccountId),

    CONSTRAINT FK_Order_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES trading.Instrument(InstrumentId),

    CONSTRAINT CK_Order_Side
        CHECK (Side IN ('BUY', 'SELL')),

    CONSTRAINT CK_Order_Type
        CHECK (OrderType IN ('MARKET', 'LIMIT')),

    CONSTRAINT CK_Order_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_Order_LimitPrice
        CHECK
        (
            (OrderType = 'MARKET' AND LimitPrice IS NULL)
            OR
            (OrderType = 'LIMIT' AND LimitPrice IS NOT NULL AND LimitPrice > 0)
        ),

    CONSTRAINT CK_Order_Status
        CHECK
        (
            Status IN
            (
                'Pending',
                'PartiallyExecuted',
                'Executed',
                'Cancelled',
                'Rejected'
            )
        )
);
GO

CREATE TABLE trading.Execution
(
    ExecutionId      BIGINT IDENTITY(1,1) NOT NULL,
    OrderId          BIGINT NOT NULL,
    ExecutedQuantity DECIMAL(19,8) NOT NULL,
    ExecutionPrice   DECIMAL(19,8) NOT NULL,
    ExecutedAt       DATETIME2(3) NOT NULL,
    CreatedAt        DATETIME2(3) NOT NULL
        CONSTRAINT DF_Execution_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Execution PRIMARY KEY (ExecutionId),

    CONSTRAINT FK_Execution_Order
        FOREIGN KEY (OrderId)
        REFERENCES trading.[Order](OrderId),

    CONSTRAINT CK_Execution_Quantity
        CHECK (ExecutedQuantity > 0),

    CONSTRAINT CK_Execution_Price
        CHECK (ExecutionPrice > 0)
);
GO

CREATE TABLE trading.Position
(
    PositionId   BIGINT IDENTITY(1,1) NOT NULL,
    AccountId    BIGINT NOT NULL,
    InstrumentId BIGINT NOT NULL,
    Quantity     DECIMAL(19,8) NOT NULL,
    AveragePrice DECIMAL(19,8) NOT NULL,
    UpdatedAt    DATETIME2(3) NOT NULL
        CONSTRAINT DF_Position_UpdatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Position PRIMARY KEY (PositionId),

    CONSTRAINT FK_Position_Account
        FOREIGN KEY (AccountId)
        REFERENCES core.Account(AccountId),

    CONSTRAINT FK_Position_Instrument
        FOREIGN KEY (InstrumentId)
        REFERENCES trading.Instrument(InstrumentId),

    CONSTRAINT UQ_Position_Account_Instrument
        UNIQUE (AccountId, InstrumentId),

    CONSTRAINT CK_Position_Quantity
        CHECK (Quantity >= 0),

    CONSTRAINT CK_Position_AveragePrice
        CHECK (AveragePrice >= 0)
);
GO

CREATE TABLE trading.Commission
(
    CommissionId   BIGINT IDENTITY(1,1) NOT NULL,
    ExecutionId    BIGINT NOT NULL,
    CommissionType VARCHAR(20) NOT NULL,
    Rate           DECIMAL(19,8) NULL,
    Amount         DECIMAL(19,4) NOT NULL,
    Currency       CHAR(3) NOT NULL,
    CreatedAt      DATETIME2(3) NOT NULL
        CONSTRAINT DF_Commission_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Commission PRIMARY KEY (CommissionId),

    CONSTRAINT FK_Commission_Execution
        FOREIGN KEY (ExecutionId)
        REFERENCES trading.Execution(ExecutionId),

    CONSTRAINT CK_Commission_Type
        CHECK (CommissionType IN ('Percentage', 'Fixed')),

    CONSTRAINT CK_Commission_Rate
        CHECK (Rate IS NULL OR Rate >= 0),

    CONSTRAINT CK_Commission_Amount
        CHECK (Amount >= 0)
);
GO

CREATE TABLE trading.CashTransaction
(
    CashTransactionId BIGINT IDENTITY(1,1) NOT NULL,
    CashAccountId     BIGINT NOT NULL,
    TransactionType   VARCHAR(20) NOT NULL,
    Amount            DECIMAL(19,4) NOT NULL,
    Currency          CHAR(3) NOT NULL,
    ReferenceType     VARCHAR(30) NULL,
    ReferenceId       BIGINT NULL,
    Description       VARCHAR(500) NULL,
    CreatedAt         DATETIME2(3) NOT NULL
        CONSTRAINT DF_CashTransaction_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_CashTransaction PRIMARY KEY (CashTransactionId),

    CONSTRAINT FK_CashTransaction_CashAccount
        FOREIGN KEY (CashAccountId)
        REFERENCES core.CashAccount(CashAccountId),

    CONSTRAINT CK_CashTransaction_Type
        CHECK
        (
            TransactionType IN
            (
                'Deposit',
                'Withdrawal',
                'Trade',
                'Commission',
                'Adjustment'
            )
        ),

    CONSTRAINT CK_CashTransaction_Amount
        CHECK (Amount <> 0)
);
GO


CREATE TABLE audit.OrderStatusHistory
(
    OrderStatusHistoryId BIGINT IDENTITY(1,1) NOT NULL,
    OrderId              BIGINT NOT NULL,
    OldStatus            VARCHAR(20) NOT NULL,
    NewStatus            VARCHAR(20) NOT NULL,
    ChangedBy            VARCHAR(100) NOT NULL,
    ChangedAt            DATETIME2(3) NOT NULL
        CONSTRAINT DF_OrderStatusHistory_ChangedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_OrderStatusHistory PRIMARY KEY (OrderStatusHistoryId),

    CONSTRAINT FK_OrderStatusHistory_Order
        FOREIGN KEY (OrderId)
        REFERENCES trading.[Order](OrderId),

    CONSTRAINT CK_OrderStatusHistory_Transition
        CHECK (OldStatus <> NewStatus)
);
GO

CREATE TABLE audit.AuditLog
(
    AuditLogId BIGINT IDENTITY(1,1) NOT NULL,
    TableName  VARCHAR(128) NOT NULL,
    RecordId   BIGINT NOT NULL,
    Action     VARCHAR(20) NOT NULL,
    ChangedBy  VARCHAR(100) NOT NULL,
    ChangedAt  DATETIME2(3) NOT NULL
        CONSTRAINT DF_AuditLog_ChangedAt DEFAULT (SYSUTCDATETIME()),
    OldValues  NVARCHAR(MAX) NULL,
    NewValues  NVARCHAR(MAX) NULL,

    CONSTRAINT PK_AuditLog PRIMARY KEY (AuditLogId),

    CONSTRAINT CK_AuditLog_Action
        CHECK (Action IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO


