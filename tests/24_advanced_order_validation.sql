USE BrokerageDB;
GO
/* Verificări read-only pentru funcțiile avansate. Nu creează sau șterge date. */
IF COL_LENGTH('trading.[Order]', 'StopPrice') IS NULL
    THROW 56001, N'Lipsește StopPrice. Rulează scriptul 17.', 1;
IF COL_LENGTH('trading.[Order]', 'CancelledQuantity') IS NULL
    THROW 56002, N'Lipsește CancelledQuantity. Rulează scriptul 20.', 1;
IF COL_LENGTH('trading.[Order]', 'TimeInForce') IS NULL
    THROW 56003, N'Lipsește TimeInForce. Rulează scriptul 21.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE object_id=OBJECT_ID('trading.usp_CancelOrderPartially'))
    THROW 56004, N'Procedura de anulare parțială lipsește.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE object_id=OBJECT_ID('trading.usp_ExecuteOrder'))
    THROW 56005, N'Procedura de execuție lipsește.', 1;

/* Integritatea cantităților și comisionului calculat la execuție. */
IF EXISTS (SELECT 1 FROM trading.[Order] o OUTER APPLY (SELECT ISNULL(SUM(e.ExecutedQuantity),0) q FROM trading.Execution e WHERE e.OrderId=o.OrderId) x WHERE o.Quantity < x.q OR o.CancelledQuantity < 0)
    THROW 56006, N'Există un ordin cu cantități nevalide.', 1;
IF EXISTS (SELECT 1 FROM trading.Execution WHERE CommissionReporting < 0 OR TradeValueReporting < 0)
    THROW 56007, N'Există o execuție cu valoare sau comision nevalid.', 1;
IF EXISTS (SELECT 1 FROM trading.[Order] WHERE OrderType IN ('STOP','STOP_LIMIT') AND StopPrice IS NULL)
    THROW 56008, N'Există un ordin STOP fără prag de declanșare.', 1;
IF EXISTS (SELECT 1 FROM trading.[Order] WHERE OrderType='STOP_LIMIT' AND LimitPrice IS NULL)
    THROW 56009, N'Există un STOP-LIMIT fără preț limită.', 1;
PRINT N'Validarea ordinelor STOP, STOP-LIMIT, anulărilor parțiale și comisioanelor a trecut.';
GO
