USE BrokerageDW;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Inserted BIGINT = 0, @Updated BIGINT = 0;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID('tempdb..#SourceOrders') IS NOT NULL DROP TABLE #SourceOrders;

    SELECT
        CONVERT(INT, CONVERT(CHAR(8), CAST(o.CreatedAt AS DATE), 112)) AS CreatedDateKey,
        CASE WHEN o.Status IN ('Executed', 'Rejected', 'Cancelled')
             THEN CONVERT(INT, CONVERT(CHAR(8), CAST(COALESCE(status_change.ChangedAt, o.UpdatedAt) AS DATE), 112)) END AS ResolutionDateKey,
        customer.CustomerKey, account.AccountKey, instrument.InstrumentKey,
        o.OrderId, o.Side, o.OrderType, o.Status AS OrderStatus, o.Quantity AS OrderedQuantity,
        CAST(ISNULL(execution_summary.ExecutedQuantity, 0) AS DECIMAL(19,8)) AS ExecutedQuantity,
        ISNULL(execution_summary.ExecutionCount, 0) AS ExecutionCount, o.LimitPrice, o.CreatedAt,
        CASE WHEN o.Status IN ('Executed', 'Rejected', 'Cancelled') THEN COALESCE(status_change.ChangedAt, o.UpdatedAt) END AS ResolvedAt,
        CASE WHEN o.Status IN ('Executed', 'Rejected', 'Cancelled') THEN DATEDIFF(MINUTE, o.CreatedAt, COALESCE(status_change.ChangedAt, o.UpdatedAt)) END AS ResolutionMinutes,
        decision.Reason AS RejectionReason
    INTO #SourceOrders
    FROM BrokerageDB.staging.[Order] o
    INNER JOIN dw.DimAccount account ON account.AccountId = o.AccountId
    INNER JOIN dw.DimCustomer customer ON customer.CustomerId = account.CustomerId
    INNER JOIN dw.DimInstrument instrument ON instrument.InstrumentId = o.InstrumentId
    OUTER APPLY (SELECT SUM(e.ExecutedQuantity) ExecutedQuantity, COUNT(*) ExecutionCount FROM BrokerageDB.staging.Execution e WHERE e.OrderId = o.OrderId) execution_summary
    OUTER APPLY (SELECT TOP (1) h.ChangedAt FROM BrokerageDB.audit.OrderStatusHistory h WHERE h.OrderId=o.OrderId AND h.NewStatus=o.Status ORDER BY h.ChangedAt DESC) status_change
    OUTER APPLY (SELECT TOP (1) d.Reason FROM BrokerageDB.audit.OrderDecision d WHERE d.OrderId=o.OrderId ORDER BY d.DecidedAt DESC) decision;

    IF EXISTS (SELECT 1 FROM #SourceOrders WHERE ExecutedQuantity > OrderedQuantity)
        THROW 54050, N'Un ordin are o cantitate executată mai mare decât cantitatea cerută.', 1;

    UPDATE target SET
        CreatedDateKey=s.CreatedDateKey, ResolutionDateKey=s.ResolutionDateKey, CustomerKey=s.CustomerKey, AccountKey=s.AccountKey, InstrumentKey=s.InstrumentKey,
        Side=s.Side, OrderType=s.OrderType, OrderStatus=s.OrderStatus, OrderedQuantity=s.OrderedQuantity, ExecutedQuantity=s.ExecutedQuantity,
        ExecutionCount=s.ExecutionCount, LimitPrice=s.LimitPrice, CreatedAt=s.CreatedAt, ResolvedAt=s.ResolvedAt, ResolutionMinutes=s.ResolutionMinutes,
        RejectionReason=s.RejectionReason, DWUpdatedAt=SYSUTCDATETIME()
    FROM dw.FactOrderLifecycle target INNER JOIN #SourceOrders s ON s.OrderId=target.OrderId
    WHERE target.CreatedDateKey<>s.CreatedDateKey OR ISNULL(target.ResolutionDateKey,-1)<>ISNULL(s.ResolutionDateKey,-1)
       OR target.CustomerKey<>s.CustomerKey OR target.AccountKey<>s.AccountKey OR target.InstrumentKey<>s.InstrumentKey
       OR target.Side<>s.Side OR target.OrderType<>s.OrderType OR target.OrderStatus<>s.OrderStatus
       OR target.OrderedQuantity<>s.OrderedQuantity OR target.ExecutedQuantity<>s.ExecutedQuantity
       OR target.ExecutionCount<>s.ExecutionCount OR ISNULL(target.LimitPrice,-1)<>ISNULL(s.LimitPrice,-1)
       OR target.CreatedAt<>s.CreatedAt OR ISNULL(target.ResolvedAt,'19000101')<>ISNULL(s.ResolvedAt,'19000101')
       OR ISNULL(target.ResolutionMinutes,-1)<>ISNULL(s.ResolutionMinutes,-1)
       OR ISNULL(target.RejectionReason,'')<>ISNULL(s.RejectionReason,'');
    SET @Updated=@@ROWCOUNT;

    INSERT INTO dw.FactOrderLifecycle
    (CreatedDateKey,ResolutionDateKey,CustomerKey,AccountKey,InstrumentKey,OrderId,Side,OrderType,OrderStatus,OrderedQuantity,ExecutedQuantity,ExecutionCount,LimitPrice,CreatedAt,ResolvedAt,ResolutionMinutes,RejectionReason)
    SELECT CreatedDateKey,ResolutionDateKey,CustomerKey,AccountKey,InstrumentKey,OrderId,Side,OrderType,OrderStatus,OrderedQuantity,ExecutedQuantity,ExecutionCount,LimitPrice,CreatedAt,ResolvedAt,ResolutionMinutes,RejectionReason
    FROM #SourceOrders s WHERE NOT EXISTS (SELECT 1 FROM dw.FactOrderLifecycle t WHERE t.OrderId=s.OrderId);
    SET @Inserted=@@ROWCOUNT;
    COMMIT TRANSACTION;
    PRINT CONCAT('FactOrderLifecycle: inserate ',@Inserted,', actualizate ',@Updated,'.');
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
