USE BrokerageDB;
GO

/*
Test: Concurență și blocări

Scop:
Demonstrate that UPDLOCK + HOLDLOCK can block
o tranzacție concurentă care încearcă să acceseze
același ordin.

Ordin folosit pentru test:
OrderId = 110006

Așteptat comportament:
- Sesiunea A începe o tranzacție.
- Sesiunea A citește ordinul folosind UPDLOCK + HOLDLOCK.
- Sesiunea B încearcă să acceseze același ordin.
- Sesiunea B este blocată.
- sys.dm_exec_requests shows LCK_M_U.
- Sesiunea B continuă după confirmarea sesiunii A.
*/


-- SESIUNEA A
-- Rulează într-o fereastră SSMS separată.

BEGIN TRANSACTION;

SELECT
    OrderId,
    AccountId,
    Status,
    Quantity,
    LimitPrice
FROM trading.[Order] WITH (UPDLOCK, HOLDLOCK)
WHERE OrderId = 110006;

-- Păstrează tranzacția deschisă în timpul testului.
-- COMMIT numai după Sesiunea B este blocată.


-- SESIUNEA B
-- Rulează într-o altă fereastră SSMS.

SELECT
    OrderId,
    AccountId,
    Status,
    Quantity,
    LimitPrice
FROM trading.[Order] WITH (UPDLOCK, HOLDLOCK)
WHERE OrderId = 110006;


-- Monitoring sesiune
-- Rulează într-o a treia fereastră SSMS.

SELECT
    r.session_id,
    r.status,
    r.command,
    r.wait_type,
    r.wait_time,
    r.blocking_session_id
FROM sys.dm_exec_requests r
WHERE r.session_id <> @@SPID;


-- Reveniți la SESIUNEA A:
-- COMMIT TRANSACTION;
