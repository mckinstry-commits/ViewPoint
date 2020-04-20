DECLARE pc CURSOR for
SELECT
	apul.KeyID
--,	apul.POCo
--,	apul.PO
--,	wo.SMCo
--,	wo.WorkOrder
--,	apul.TaxType
--,	apul.TaxGroup
--,	apul.TaxCode
--,	ss.JCCo
--,	ss.Job
,   COALESCE(apul.TaxType,1) AS DEF_TaxType
,	ss.TaxGroup AS SM_TaxGroup
,	ss.TaxCode AS SM_TaxCode
FROM 
	POIT apul join
	SMWorkOrder wo ON 
		apul.SMCo=wo.SMCo
	AND apul.SMWorkOrder=wo.WorkOrder JOIN
    SMServiceSite ss ON
		wo.SMCo=ss.SMCo
	AND wo.ServiceSite=ss.ServiceSite
WHERE
	apul.POCo<100
AND	( apul.TaxCode IS null OR apul.TaxType IS NULL )
--AND 
--(
----	ss.TaxCode IN ( SELECT DISTINCT TaxCode FROM HQTX WHERE MultiLevel='Y' AND TaxGroup=1) --'031100','021000'  -- Eliminate Invalid Tax Codes
-- apul.KeyID NOT IN ( 4669566, 4669726,4669735,4670255 ) -- Eliminate PO's tied to Job with no Cost Types
--)
--AND ss.Job = ' 82463-001'
FOR READ ONLY

DECLARE @k int
DECLARE @taxtype INT
DECLARE @taxgroup bGroup
DECLARE @taxcode bTaxCode

OPEN pc
FETCH pc INTO @k, @taxtype, @taxgroup, @taxcode
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE POIT SET TaxGroup=@taxgroup, TaxCode=@taxcode, TaxType=@taxtype WHERE KeyID=@k

	FETCH pc INTO @k, @taxtype, @taxgroup, @taxcode
END

CLOSE pc
DEALLOCATE pc
go

