USE BrokerageDB;
GO

CREATE OR ALTER PROCEDURE trading.usp_CreateOrder
    @AccountId BIGINT, @InstrumentId BIGINT, @Side VARCHAR(4), @OrderType VARCHAR(10),
    @Quantity DECIMAL(19,8), @LimitPrice DECIMAL(19,8) = NULL, @StopPrice DECIMAL(19,8) = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    DECLARE @Currency CHAR(3), @OrderId BIGINT, @RequiredCash DECIMAL(19,4), @ReservePrice DECIMAL(19,8);
    IF @Side NOT IN('BUY','SELL') THROW 50030,N'Direcția ordinului trebuie să fie BUY sau SELL.',1;
    IF @OrderType NOT IN('MARKET','LIMIT','STOP','STOP_LIMIT') THROW 50031,N'Tip de ordin invalid.',1;
    IF @Quantity<=0 THROW 50032,N'Cantitatea trebuie să fie mai mare decât zero.',1;
    IF (@OrderType='MARKET' AND (@LimitPrice IS NOT NULL OR @StopPrice IS NOT NULL)) OR (@OrderType='LIMIT' AND (@LimitPrice IS NULL OR @StopPrice IS NOT NULL)) OR (@OrderType='STOP' AND (@StopPrice IS NULL OR @LimitPrice IS NOT NULL)) OR (@OrderType='STOP_LIMIT' AND (@StopPrice IS NULL OR @LimitPrice IS NULL)) THROW 50033,N'Prețurile nu sunt valide pentru tipul de ordin selectat.',1;
    BEGIN TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM core.Account a JOIN core.Customer c ON c.CustomerId=a.CustomerId JOIN core.KYC k ON k.CustomerId=c.CustomerId WHERE a.AccountId=@AccountId AND a.Status='Active' AND c.Status='Active' AND k.Status='Approved') THROW 50034,N'Contul sau KYC-ul nu permite tranzacționarea.',1;
    SELECT @Currency=Currency FROM trading.Instrument WHERE InstrumentId=@InstrumentId AND IsActive=1;
    IF @Currency IS NULL THROW 50035,N'Instrument inexistent sau inactiv.',1;
    SET @ReservePrice=COALESCE(@LimitPrice,@StopPrice,0);
    IF @Side='BUY' AND @ReservePrice>0 BEGIN SET @RequiredCash=ROUND(@Quantity*@ReservePrice*1.0025,4); IF NOT EXISTS(SELECT 1 FROM core.CashAccount WHERE AccountId=@AccountId AND Currency=@Currency AND AvailableBalance>=@RequiredCash) THROW 50037,N'Fonduri insuficiente: numerarul disponibil nu acoperă valoarea ordinului și comisionul estimat.',1; END;
    IF @Side='SELL' AND NOT EXISTS(SELECT 1 FROM trading.Position WHERE AccountId=@AccountId AND InstrumentId=@InstrumentId AND Quantity>=@Quantity) THROW 50038,N'Cantitate insuficientă în poziție.',1;
    INSERT trading.[Order](AccountId,InstrumentId,Side,OrderType,Quantity,LimitPrice,StopPrice,Status) VALUES(@AccountId,@InstrumentId,@Side,@OrderType,@Quantity,@LimitPrice,@StopPrice,'Pending');
    SET @OrderId=SCOPE_IDENTITY(); COMMIT; SELECT @OrderId OrderId,'Pending' Status;
END;
GO
