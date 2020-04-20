use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnARDetail_temp')
begin
	print 'DROP FUNCTION mers.mfnARDetail_temp'
	DROP FUNCTION mers.mfnARDetail_temp
end
go

print 'CREATE FUNCTION mers.mfnARDetail_temp'
GO


CREATE FUNCTION mers.mfnARDetail_temp 
(	
	-- Declare Input Parameters
	@ARCo bCompany = NULL
,	@Contract	bContract = null
,	@Invoice VARCHAR(10) = NULL
)
RETURNS  @retTable TABLE
(
	ARCo			bCompany	NOT NULL
,	Mth				bMonth		NOT NULL
,	ARTrans			bTrans		NOT NULL
,	CustGroup		bGroup		NULL
,	Customer		bCustomer	null
,	Invoice			VARCHAR(10)	NULL 
,	InvoiceDesc		bDesc		NULL 
,	DueDate			bDate		NULL
,	InvTranDate		bDate		NULL
,	InvTranType		char(1)		NULL
,	InvAmountDue	bDollar		NULL
,	InvARLine		SMALLINT	NULL
,	InvARLineDesc	bDesc		NULL 
,	InvAmount		bDollar		NULL
,	InvDiscOffered	bDollar		NULL
,	InvRetainage	bDollar		null
,	PmtTranDate		bDate		NULL
,	PmtTranType		char(1)		NULL
,	PmtARLine		SMALLINT	NULL
,	PmtAmount		bDollar		null
,	PmtDiscTaken	bDollar		null
,	PmtRetainage	bDollar		null
,	ApplyMth		bMonth		NULL
,	ApplyLine		SMALLINT	NULL
,	ApplyTrans		bTrans		NULL
,	CheckDate		bDate		NULL
,	CheckNo			VARCHAR(10)	NULL
,	udCheckNo		VARCHAR(20)	NULL
,	PayFullDate		bDate		NULL
,	GLCo			bCompany	NULL
,	GLAcct			bGLAcct		NULL
,	JCCo			bCompany	NULL 
,	Contract		bContract	NULL
,	Item			bContractItem		NULL 
,	Job				bJob		NULL 
,	SMCo			bCompany	NULL
,	WorkOrder		bWO			null
)
BEGIN

--SELECT DISTINCT ARTransType FROM ARTH
/*
C - Credit Memo
W - Write Off
A - Adjustment
I - Invoice
R - Release Retainage
M - ?? Misc ??
P - Payment
*/
--SELECT * FROM ARTH WHERE ARTransType='P'

WITH arinv AS 
(
SELECT
	arth.ARCo
,	arth.Mth
,	arth.ARTrans
,	arth.CustGroup
,	arth.Customer
,	arth.Invoice
,	arth.Description AS InvoiceDesc
,	arth.DueDate
,	arth.TransDate
,	arth.ARTransType
,	arth.AmountDue
,	artl.LineType
,	artl.ARLine
,	artl.Description AS InvARLineDesc
,	artl.Amount
,	artl.DiscOffered
,	artl.Retainage
,	arth.PayFullDate
,	artl.ApplyMth
,	artl.ApplyLine
,	artl.ApplyTrans
,	artl.GLCo
,	artl.GLAcct
,	artl.JCCo
,	artl.Contract
,	artl.Item
,	artl.Job
,	artl.udSMCo AS SMCo
,	artl.udWorkOrder AS WorkOrder
FROM 
	HQCO hqco
JOIN	ARTH arth ON
	hqco.HQCo=arth.ARCo
AND hqco.udTESTCo<>'Y'
JOIN ARTL artl ON
	arth.ARCo=artl.ARCo
AND arth.Mth=artl.Mth
AND arth.ARTrans=artl.ARTrans
AND arth.ARTransType='I'
WHERE 
	(arth.ARCo=@ARCo OR @ARCo IS NULL)
AND	(arth.Invoice=@Invoice OR @Invoice IS NULL)
AND (artl.Contract=@Contract OR @Contract IS NULL)
)
INSERT @retTable
(	
	ARCo			--bCompany	NOT NULL
,	Mth				--bMonth		NOT NULL
,	ARTrans			--bTrans		NOT NULL
,	CustGroup		--bGroup		NOT NULL
,	Customer		--bCustomer	NOT null
,	Invoice			--VARCHAR(10)	NOT NULL 
,	InvoiceDesc		--bDesc	NOT NULL 
,	DueDate			--bDate		NULL
,	InvTranDate		--bDate		NULL
,	InvTranType		--char(1)		NULL
,	InvAmountDue	--bDollar		NULL
,	InvARLine		--SMALLINT	null
,	InvARLineDesc	--bDesc	NOT NULL 
,	InvAmount		--bDollar		NULL
,	InvDiscOffered	--bDollar		NULL
,	InvRetainage	--bDollar		null
,	PmtTranDate		--bDate		NULL
,	PmtTranType		--char(1)		NULL
,	PmtARLine		--SMALLINT	NULL
,	PmtAmount		--bDollar		null
,	PmtDiscTaken	--bDollar		null
,	PmtRetainage	--bDollar		null
,	ApplyMth		--bMonth		NULL
,	ApplyLine		--SMALLINT	NULL
,	ApplyTrans		--bTrans		NULL
,	CheckDate		--bDate		NULL
,	CheckNo			--VARCHAR(10)	NULL
,	udCheckNo		--VARCHAR(20)	NULL
,	PayFullDate		--bDate	NULLl
,	GLCo			--bCompany	NULL
,	GLAcct			--bGLAcct		NULL
,	JCCo			--bCompany	NULL 
,	Contract		--bContract	NULL
,	Item			--bItem		NULL 
,	Job				--bJob		NULL 
,	SMCo			--bCompany	NULL
,	WorkOrder		--bWO			null
)
SELECT
	arinv.ARCo
,	arinv.Mth
,	arinv.ARTrans
--,	arinv.ARTransType
,	arth.CustGroup
,	arth.Customer
,	arinv.Invoice
,	arinv.InvoiceDesc
,	arinv.DueDate
,	arinv.TransDate AS InvTranDate
,	arinv.ARTransType
,	arinv.AmountDue AS InvAmountDue
--,	arinv.LineType
,	arinv.ARLine AS InvARLine
,	arinv.InvARLineDesc
,	arinv.Amount AS InvAmount
,	arinv.DiscOffered AS InvDiscOffered
,	arinv.Retainage AS InvRetainage
--,	arinv.ApplyMth
--,	arinv.ApplyLine
--,	arinv.ApplyTrans
--,	arth.ARTransType
,	arth.TransDate AS PmtTranDate
,	arth.ARTransType
--,	artl.LineType
,	artl.ARLine AS PmtARLine
,	artl.Amount AS PmtAmount
,	artl.DiscTaken AS PmtDiscTaken
,	artl.Retainage AS PmtRetainage
,	artl.ApplyMth
,	artl.ApplyLine
,	artl.ApplyTrans
,	arth.CheckDate 
,	arth.CheckNo
,	arth.udCheckNo
,	arinv.PayFullDate
,	arinv.GLCo
,	arinv.GLAcct
,	arinv.JCCo
,	arinv.Contract
,	arinv.Item
,	arinv.Job
,	arinv.SMCo
,	arinv.WorkOrder
FROM 
	arinv arinv
JOIN ARTL artl on
	artl.ARCo=arinv.ARCo
AND artl.ApplyMth=arinv.ApplyMth
AND artl.ApplyLine=arinv.ApplyLine
AND artl.ApplyTrans=arinv.ApplyTrans
--AND arinv.Invoice='     55020'
JOIN ARTH arth on
	arth.ARCo=artl.ARCo
AND arth.Mth=artl.Mth
AND arth.ARTrans=artl.ARTrans
AND arth.ARTransType<>'I'
ORDER BY
	arinv.ARCo
,	arinv.Mth
,	arinv.Invoice
--,	arinv.TransDate
--,	arth.TransDate
,	arinv.ARTrans
,	arinv.ARLine

RETURN 

END 

go

DECLARE @ARCo bCompany
DECLARE @Contract bContract
DECLARE @Invoice VARCHAR(10) 
SET @ARCo=NULL 
--SET @Contract=' 10204-'
SET @Invoice='     55020' 
--SET @Invoice='     52184'
--SET @Invoice='     64894'
--SET @Invoice='  20008913'

SELECT * FROM mers.mfnARDetail_temp(@ARCo,@Contract,@Invoice) a

SELECT 
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice
,	a.ApplyLine
,	CAST(AVG(a.InvAmount)-AVG(a.InvDiscOffered)-AVG(a.InvRetainage) AS DECIMAL(18,2)) AS InvTotal
,	SUM(a.PmtAmount)+SUM(a.PmtDiscTaken)+SUM(a.PmtRetainage) AS PmtTotal 
,	(AVG(a.InvAmount)-AVG(a.InvDiscOffered)-AVG(a.InvRetainage))+(SUM(a.PmtAmount)+SUM(a.PmtDiscTaken)+SUM(a.PmtRetainage)) AS Balance 
,	AVG(a.InvRetainage) AS Retainage
FROM 
	mers.mfnARDetail_temp(@ARCo,@Contract,@Invoice) a 
GROUP BY 
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice
,	a.ApplyLine

SELECT
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice
,	SUM(InvTotal) AS InvTotal
,	SUM(PmtTotal) AS PmtTotal
,	SUM(Balance) AS Balance
,	SUM(Retainage) AS Retainage
from 
(
SELECT 
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice
,	a.ApplyLine
,	CAST(AVG(a.InvAmount)-AVG(a.InvDiscOffered)-AVG(a.InvRetainage) AS DECIMAL(18,2)) AS InvTotal
,	SUM(a.PmtAmount)+SUM(a.PmtDiscTaken)+SUM(a.PmtRetainage) AS PmtTotal 
,	(AVG(a.InvAmount)-AVG(a.InvDiscOffered)-AVG(a.InvRetainage))+(SUM(a.PmtAmount)+SUM(a.PmtDiscTaken)+SUM(a.PmtRetainage)) AS Balance 
,	AVG(a.InvRetainage) AS Retainage
FROM 
	mers.mfnARDetail_temp(@ARCo,@Contract,@Invoice) a 
GROUP BY 
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice
,	a.ApplyLine
) a
GROUP BY
	a.ARCo
,	a.Mth
,	a.ARTrans
,	a.Invoice

