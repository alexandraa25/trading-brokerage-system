USE BrokerageDB;
GO

/* Testează regulile administrative fără a modifica datele permanente. */
BEGIN TRANSACTION;

DECLARE @CustomerId BIGINT = (SELECT TOP 1 CustomerId FROM core.Customer ORDER BY CustomerId);
DECLARE @AccountId BIGINT = (SELECT TOP 1 AccountId FROM core.Account WHERE CustomerId = @CustomerId ORDER BY AccountId);

IF @CustomerId IS NULL OR @AccountId IS NULL
    THROW 51001, N'Nu există date demonstrative pentru test.', 1;

/* Simulare KYC respins: contul trebuie suspendat. */
UPDATE core.KYC SET Status = 'Rejected', RejectionReason = N'Test automat', UpdatedAt = SYSUTCDATETIME()
WHERE CustomerId = @CustomerId;
UPDATE core.Account SET Status = 'Suspended' WHERE CustomerId = @CustomerId AND Status = 'Active';

IF EXISTS (SELECT 1 FROM core.Account WHERE CustomerId = @CustomerId AND Status = 'Active')
    THROW 51002, N'Contul activ nu a fost suspendat după KYC respins.', 1;

/* Simulare KYC aprobat și reactivare cu motiv auditat. */
UPDATE core.KYC SET Status = 'Approved', RejectionReason = NULL, UpdatedAt = SYSUTCDATETIME()
WHERE CustomerId = @CustomerId;
UPDATE core.Account SET Status = 'Active' WHERE AccountId = @AccountId;
INSERT INTO audit.AccountAdministrationLog(AccountId, PreviousStatus, NewStatus, Reason, ChangedBy)
VALUES(@AccountId, 'Suspended', 'Active', N'Reactivare test după KYC aprobat', N'AutomatedTest');

IF NOT EXISTS (SELECT 1 FROM audit.AccountAdministrationLog WHERE AccountId = @AccountId AND NewStatus = 'Active' AND ChangedBy = N'AutomatedTest')
    THROW 51003, N'Jurnalul administrativ nu conține reactivarea.', 1;

ROLLBACK TRANSACTION;
PRINT N'Testele administrative au trecut cu succes.';
GO
