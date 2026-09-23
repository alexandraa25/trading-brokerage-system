USE BrokerageDW;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID('tempdb..#SourceKyc') IS NOT NULL DROP TABLE #SourceKyc;
 SELECT CONVERT(INT,CONVERT(CHAR(8),CAST(k.CreatedAt AS DATE),112)) SubmittedDateKey,
        CASE WHEN k.Status IN ('Approved','Rejected') THEN CONVERT(INT,CONVERT(CHAR(8),CAST(COALESCE(k.VerifiedAt,k.UpdatedAt) AS DATE),112)) END ResolvedDateKey,
        c.CustomerKey,k.KycId,k.Status KycStatus,k.DocumentType,k.CreatedAt SubmittedAt,
        CASE WHEN k.Status IN ('Approved','Rejected') THEN COALESCE(k.VerifiedAt,k.UpdatedAt) END ResolvedAt,
        CASE WHEN k.Status IN ('Approved','Rejected') THEN k.VerifiedBy END ResolvedBy,
        CASE WHEN k.Status IN ('Approved','Rejected') THEN DATEDIFF(DAY,k.CreatedAt,COALESCE(k.VerifiedAt,k.UpdatedAt)) END ResolutionDays,
        CASE WHEN k.Status='Rejected' THEN k.RejectionReason END RejectionReason
 INTO #SourceKyc
 FROM BrokerageDB.core.KYC k INNER JOIN dw.DimCustomer c ON c.CustomerId=k.CustomerId;
 IF EXISTS (SELECT 1 FROM #SourceKyc s LEFT JOIN dw.DimDate d ON d.DateKey=s.SubmittedDateKey WHERE d.DateKey IS NULL)
  THROW 54060,N'Calendarul dimensional nu acoperă toate dosarele KYC.',1;
 UPDATE t SET SubmittedDateKey=s.SubmittedDateKey,ResolvedDateKey=s.ResolvedDateKey,CustomerKey=s.CustomerKey,KycStatus=s.KycStatus,DocumentType=s.DocumentType,SubmittedAt=s.SubmittedAt,ResolvedAt=s.ResolvedAt,ResolvedBy=s.ResolvedBy,ResolutionDays=s.ResolutionDays,RejectionReason=s.RejectionReason,DWUpdatedAt=SYSUTCDATETIME()
 FROM dw.FactKyc t INNER JOIN #SourceKyc s ON s.KycId=t.KycId;
 INSERT INTO dw.FactKyc(SubmittedDateKey,ResolvedDateKey,CustomerKey,KycId,KycStatus,DocumentType,SubmittedAt,ResolvedAt,ResolvedBy,ResolutionDays,RejectionReason)
 SELECT SubmittedDateKey,ResolvedDateKey,CustomerKey,KycId,KycStatus,DocumentType,SubmittedAt,ResolvedAt,ResolvedBy,ResolutionDays,RejectionReason FROM #SourceKyc s WHERE NOT EXISTS(SELECT 1 FROM dw.FactKyc t WHERE t.KycId=s.KycId);
 COMMIT TRANSACTION;
 PRINT N'FactKyc a fost încărcat cu succes.';
END TRY
BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
GO
