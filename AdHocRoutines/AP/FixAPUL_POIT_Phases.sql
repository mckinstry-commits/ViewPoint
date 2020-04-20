-- Clear POIT PhaseGroup and Phase from erroneous update from SMWorkOrder (should have only updated SMPhaseGroup and SMPhase)
DECLARE pocur CURSOR for
SELECT POCo, PO, KeyID, SMWorkOrder FROM POIT WHERE SMWorkOrder IS NOT NULL AND SMPhase IS NOT NULL AND Phase IS NOT NULL 
AND KeyID IN ( 4669566, 4669726,4669735,4670255 )
ORDER BY KeyID FOR READ ONLY

DECLARE @k INT
DECLARE @POCo bCompany
DECLARE @PO bPO
DECLARE @SMWorkOrder int

OPEN pocur
FETCH pocur INTO @POCo, @PO,@k ,@SMWorkOrder

WHILE @@FETCH_STATUS=0
BEGIN
	
	PRINT 
		CAST(@POCo AS CHAR(3)) + ' : '
	+	CAST(@PO AS CHAR(20))
	+	CAST(@k AS CHAR(10))
	+	CAST(@SMWorkOrder AS CHAR(10))

	--UPDATE POIT SET PhaseGroup=NULL, Phase=NULL WHERE KeyID=@k


	FETCH pocur INTO @POCo, @PO,@k,@SMWorkOrder
END

CLOSE pocur
DEALLOCATE pocur
GO



BEGIN TRAN
UPDATE APUL SET APUL.TaxGroup=t1.SM_TaxGroup, APUL.TaxCode=t1.SM_TaxCode, APUL.TaxType=t1.DEF_TaxType
FROM
(
SELECT
	apul.KeyID
,	apul.APCo
,	apul.UIMth
,	apul.UISeq
,	apul.TaxType
,	apul.TaxGroup
,	apul.TaxCode
,   COALESCE(apul.TaxType,1) AS DEF_TaxType
,	ss.TaxGroup AS SM_TaxGroup
,	ss.TaxCode AS SM_TaxCode
FROM 
	APUL apul join
	SMWorkOrder wo ON 
		apul.SMCo=wo.SMCo
	AND apul.SMWorkOrder=wo.WorkOrder JOIN
    SMServiceSite ss ON
		wo.SMCo=ss.SMCo
	AND wo.ServiceSite=ss.ServiceSite
WHERE
	apul.TaxAmt <> 0
AND ( apul.TaxCode IS null OR apul.TaxType IS NULL )
) t1
WHERE
	APUL.KeyID=t1.KeyID

IF @@ERROR<>0
	ROLLBACK TRAN 
ELSE
	COMMIT TRAN




