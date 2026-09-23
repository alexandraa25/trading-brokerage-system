USE BrokerageDW;
GO
IF (SELECT COUNT(*) FROM dw.FactKyc)<>(SELECT COUNT(*) FROM BrokerageDB.core.KYC)
 THROW 55040,N'Numărul dosarelor KYC diferă de sursă.',1;
IF EXISTS(SELECT KycId FROM dw.FactKyc GROUP BY KycId HAVING COUNT(*)>1)
 THROW 55041,N'Există dosare KYC duplicate.',1;
IF EXISTS(SELECT 1 FROM dw.FactKyc WHERE ResolutionDays<0)
 THROW 55042,N'Există durate KYC nevalide.',1;
SELECT KycStatus,COUNT(*) AS NumarDosare,AVG(CAST(ResolutionDays AS DECIMAL(19,2))) AS MedieZileSolutionare FROM dw.FactKyc GROUP BY KycStatus;
PRINT N'Validarea FactKyc s-a finalizat cu succes.';
GO
