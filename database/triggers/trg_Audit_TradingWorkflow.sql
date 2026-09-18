USE BrokerageDB;
GO

/* Istoricul detaliat al stării ordinului este păstrat separat. Acest trigger adaugă
   ordinul în jurnalul de audit comun entităților. */
CREATE OR ALTER TRIGGER trading.trg_Order_AuditLog
ON trading.[Order]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.AuditLog
        (TableName, RecordId, Action, ChangedBy, OldValues, NewValues)
    SELECT
        'trading.Order',
        COALESCE(i.OrderId, d.OrderId),
        CASE WHEN d.OrderId IS NULL THEN 'INSERT'
             WHEN i.OrderId IS NULL THEN 'DELETE'
             ELSE 'UPDATE' END,
        SUSER_SNAME(),
        CASE WHEN d.OrderId IS NULL THEN NULL ELSE
            (SELECT d.AccountId, d.InstrumentId, d.Side, d.OrderType,
                    d.Quantity, d.LimitPrice, d.Status
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
        CASE WHEN i.OrderId IS NULL THEN NULL ELSE
            (SELECT i.AccountId, i.InstrumentId, i.Side, i.OrderType,
                    i.Quantity, i.LimitPrice, i.Status
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.OrderId = i.OrderId;
END;
GO

CREATE OR ALTER TRIGGER core.trg_Customer_AuditLog
ON core.Customer
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.AuditLog
        (TableName, RecordId, Action, ChangedBy, OldValues, NewValues)
    SELECT 'core.Customer', COALESCE(i.CustomerId, d.CustomerId),
           CASE WHEN d.CustomerId IS NULL THEN 'INSERT'
                WHEN i.CustomerId IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
           SUSER_SNAME(),
           CASE WHEN d.CustomerId IS NULL THEN NULL ELSE
               (SELECT d.CustomerTypeId, d.FirstName, d.LastName, d.Email,
                       d.Status FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.CustomerId IS NULL THEN NULL ELSE
               (SELECT i.CustomerTypeId, i.FirstName, i.LastName, i.Email,
                       i.Status FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.CustomerId = i.CustomerId;
END;
GO

CREATE OR ALTER TRIGGER core.trg_KYC_AuditLog
ON core.KYC
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.AuditLog
        (TableName, RecordId, Action, ChangedBy, OldValues, NewValues)
    SELECT 'core.KYC', COALESCE(i.KycId, d.KycId),
           CASE WHEN d.KycId IS NULL THEN 'INSERT'
                WHEN i.KycId IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
           SUSER_SNAME(),
           CASE WHEN d.KycId IS NULL THEN NULL ELSE
               (SELECT d.CustomerId, d.Status, d.DocumentType, d.VerifiedAt,
                       d.VerifiedBy, d.RejectionReason
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.KycId IS NULL THEN NULL ELSE
               (SELECT i.CustomerId, i.Status, i.DocumentType, i.VerifiedAt,
                       i.VerifiedBy, i.RejectionReason
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.KycId = i.KycId;
END;
GO

CREATE OR ALTER TRIGGER core.trg_Account_AuditLog
ON core.Account
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.AuditLog
        (TableName, RecordId, Action, ChangedBy, OldValues, NewValues)
    SELECT 'core.Account', COALESCE(i.AccountId, d.AccountId),
           CASE WHEN d.AccountId IS NULL THEN 'INSERT'
                WHEN i.AccountId IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
           SUSER_SNAME(),
           CASE WHEN d.AccountId IS NULL THEN NULL ELSE
               (SELECT d.CustomerId, d.AccountNumber, d.Currency, d.Status,
                       d.ClosedAt FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.AccountId IS NULL THEN NULL ELSE
               (SELECT i.CustomerId, i.AccountNumber, i.Currency, i.Status,
                       i.ClosedAt FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.AccountId = i.AccountId;
END;
GO

CREATE OR ALTER TRIGGER trading.trg_Execution_AuditLog
ON trading.Execution
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.AuditLog
        (TableName, RecordId, Action, ChangedBy, OldValues, NewValues)
    SELECT 'trading.Execution', COALESCE(i.ExecutionId, d.ExecutionId),
           CASE WHEN d.ExecutionId IS NULL THEN 'INSERT'
                WHEN i.ExecutionId IS NULL THEN 'DELETE' ELSE 'UPDATE' END,
           SUSER_SNAME(),
           CASE WHEN d.ExecutionId IS NULL THEN NULL ELSE
               (SELECT d.OrderId, d.ExecutedQuantity, d.ExecutionPrice,
                       d.ExecutedAt FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
           CASE WHEN i.ExecutionId IS NULL THEN NULL ELSE
               (SELECT i.OrderId, i.ExecutedQuantity, i.ExecutionPrice,
                       i.ExecutedAt FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.ExecutionId = i.ExecutionId;
END;
GO
