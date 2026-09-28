USE BrokerageDB;
GO
/* Date demonstrative: necesită scripturile 19, 20 și 21. */
DECLARE @OrderTypeConstraint sysname, @OrderTypeSql nvarchar(max);
SELECT TOP 1 @OrderTypeConstraint = name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID('trading.[Order]')
  AND name LIKE 'CK_Order_Type%'
  AND definition NOT LIKE '%STOP_LIMIT%';
IF @OrderTypeConstraint IS NOT NULL
BEGIN
    SET @OrderTypeSql = N'ALTER TABLE trading.[Order] DROP CONSTRAINT ' + QUOTENAME(@OrderTypeConstraint) + N';';
    EXEC sys.sp_executesql @OrderTypeSql;
END;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID('trading.[Order]') AND definition LIKE '%STOP_LIMIT%')
    ALTER TABLE trading.[Order] ADD CONSTRAINT CK_Order_Type_Advanced_Demo CHECK (OrderType IN ('MARKET','LIMIT','STOP','STOP_LIMIT'));
GO
DECLARE @AccountId BIGINT, @InstrumentId BIGINT, @Price DECIMAL(19,8);
SELECT TOP 1 @AccountId=a.AccountId, @InstrumentId=i.InstrumentId, @Price=q.MarketPrice
FROM core.Account a
JOIN core.Customer c ON c.CustomerId=a.CustomerId AND c.Status='Active'
JOIN core.KYC k ON k.CustomerId=c.CustomerId AND k.Status='Approved'
CROSS JOIN (SELECT TOP 1 InstrumentId FROM trading.Instrument WHERE IsActive=1 ORDER BY InstrumentId) i
OUTER APPLY (SELECT TOP 1 MarketPrice FROM trading.MarketQuote WHERE InstrumentId=i.InstrumentId ORDER BY QuoteDate DESC) q
WHERE a.Status='Active' AND q.MarketPrice IS NOT NULL;
IF @AccountId IS NULL THROW 57001,N'Nu există cont activ, KYC aprobat și cotație pentru datele demo.',1;
IF NOT EXISTS (SELECT 1 FROM trading.[Order] WHERE OrderType='STOP' AND Status='Triggered')
 INSERT trading.[Order](AccountId,InstrumentId,Side,OrderType,Quantity,OriginalQuantity,CancelledQuantity,StopPrice,Status,TimeInForce)
 VALUES(@AccountId,@InstrumentId,'BUY','STOP',5,5,0,@Price*.99,'Triggered','GTC');
IF NOT EXISTS (SELECT 1 FROM trading.[Order] WHERE OrderType='STOP_LIMIT' AND Status='PartiallyExecuted')
 INSERT trading.[Order](AccountId,InstrumentId,Side,OrderType,Quantity,OriginalQuantity,CancelledQuantity,StopPrice,LimitPrice,Status,TimeInForce)
 VALUES(@AccountId,@InstrumentId,'BUY','STOP_LIMIT',8,10,0,@Price*.99,@Price*1.01,'PartiallyExecuted','GTC');
IF NOT EXISTS (SELECT 1 FROM trading.[Order] WHERE CancelledQuantity>0)
 INSERT trading.[Order](AccountId,InstrumentId,Side,OrderType,Quantity,OriginalQuantity,CancelledQuantity,LimitPrice,Status,TimeInForce)
 VALUES(@AccountId,@InstrumentId,'BUY','LIMIT',7,10,3,@Price*1.02,'Pending','GTC');
PRINT N'Datele demonstrative pentru ordine avansate au fost adăugate.';
GO
