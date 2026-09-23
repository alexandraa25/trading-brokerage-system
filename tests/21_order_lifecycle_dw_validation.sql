USE BrokerageDW;
GO
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM dw.FactOrderLifecycle) <> (SELECT COUNT(*) FROM BrokerageDB.staging.[Order])
    THROW 55030, N'Numărul ordinelor din depozit diferă de staging.', 1;
IF EXISTS (SELECT OrderId FROM dw.FactOrderLifecycle GROUP BY OrderId HAVING COUNT(*) > 1)
    THROW 55031, N'Există ordine duplicate în FactOrderLifecycle.', 1;
IF EXISTS (SELECT 1 FROM dw.FactOrderLifecycle WHERE ExecutedQuantity > OrderedQuantity OR RemainingQuantity < 0)
    THROW 55032, N'Cantitatea unui ordin este nevalidă.', 1;
SELECT OrderStatus, COUNT(*) AS NumarOrdine, AVG(CAST(ResolutionMinutes AS DECIMAL(19,2))) AS MedieMinuteSolutionare
FROM dw.FactOrderLifecycle GROUP BY OrderStatus ORDER BY OrderStatus;
PRINT N'Validarea FactOrderLifecycle s-a finalizat cu succes.';
GO
