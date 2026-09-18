USE BrokerageDB;
GO

-- =============================================
-- Existent executions
-- =============================================

SELECT
    e.ExecutionId,
    e.OrderId,
    e.ExecutedQuantity,
    e.ExecutionPrice,
    e.ExecutedAt
FROM trading.Execution e
ORDER BY e.ExecutionId;
GO


-- =============================================
-- Existent commissions
-- =============================================

SELECT
    CommissionId,
    ExecutionId,
    CommissionType,
    Rate,
    Amount,
    Currency
FROM trading.Commission
ORDER BY CommissionId;
GO


-- =============================================
-- Existent positions
-- =============================================

SELECT
    PositionId,
    AccountId,
    InstrumentId,
    Quantity,
    AveragePrice,
    UpdatedAt
FROM trading.Position
ORDER BY PositionId;
GO
