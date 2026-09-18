USE BrokerageDB;
GO

CREATE OR ALTER TRIGGER trading.trg_Order_StatusHistory
ON trading.[Order]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.OrderStatusHistory
    (
        OrderId,
        OldStatus,
        NewStatus,
        ChangedBy
    )
    SELECT
        i.OrderId,
        d.Status,
        i.Status,
        SUSER_SNAME()
    FROM inserted i
    INNER JOIN deleted d
        ON d.OrderId = i.OrderId
    WHERE ISNULL(d.Status, '') <> ISNULL(i.Status, '');
END;
GO
