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
	@ARCo bCompany		= NULL
,	@Customer bCustomer		= NULL
,	@Contract bContract	= NULL
,	@Invoice VARCHAR(10)= NULL 
,	@AgeDate bDate		= NULL
)
RETURNS  @retTable TABLE
(
	ARCo			bCompany	NOT NULL
,	Mth				bMonth		NOT NULL
,	ARTrans			bTrans		NOT NULL
,	CustGroup		bGroup		NULL
,	Customer		bCustomer	null
,	ARTransType		CHAR(1)		NULL
,	Invoice			VARCHAR(10)	NULL 
,	InvoiceDesc		bDesc		NULL 
,	InvAmountDue	bDollar		NULL
,	Amount			bDollar		NULL
,	DiscOffered		bDollar		NULL
,	Retainage		bDollar		NULL
,	DueDate			bDate		NULL
,	AgeDate			bDate		NULL
,	DaysFromAge		INT			NULL
,	AgeAmount		bDollar		NULL 
,	DueCurrent		bDollar		NULL 
,	Due30to60		bDollar		NULL 
,	Due60to90		bDollar		NULL 
,	Due90to120		bDollar		NULL 
,	Due120Plus		bDollar		NULL 
,	CheckNo			VARCHAR(10)	NULL
,	LongCheckNo		VARCHAR(20)	NULL
,	CheckDate		bDate		NULL
,	GLCo			bCompany	NULL
,	GLAcct			bGLAcct		NULL
,	JCCo			bCompany	NULL 
,	Contract		bContract	NULL
,	Item			bContractItem		NULL 
,	Job				bJob		NULL 
,	SMCo			bCompany	NULL
,	WorkOrder		bWO			null
,	ApplyMth		bMonth		NULL
,	ApplyTrans		bTrans		NULL
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

WITH ar_txn AS 
(
	SELECT
		artl.ARCo
	,	artl.ApplyMth 
	,	artl.ApplyTrans
	,	artl.ApplyLine
	,	artl.GLCo
	,	artl.GLAcct
	,	arth.JCCo
	,	arth.Contract
	,	artl.Item
	,	artl.Job
	,	artl.udSMCo
	,	artl.udWorkOrder
	,	arth.Invoice
	,	arth.Description AS InvoiceDesc
	,	arth.AmountDue
	,	arth.CreditAmt
	,	arth.DueDate
	FROM 
		ARTL artl 
	JOIN ARTH arth ON
		artl.ARCo=arth.ARCo
	AND artl.Mth=arth.Mth	
	AND artl.ARTrans=arth.ARTrans
	WHERE 
		( arth.ARCo=@ARCo OR @ARCo IS NULL)
	AND ( arth.Customer=@Customer OR @Customer IS NULL)
	AND ( artl.Contract=@Contract OR @Contract IS NULL)
	AND ( arth.Invoice=@Invoice OR @Invoice IS NULL)
)
INSERT @retTable 
(
	ARCo			--bCompany	NOT NULL
,	Mth				--bMonth		NOT NULL
,	ARTrans			--bTrans		NOT NULL
,	CustGroup		--bGroup		NULL
,	Customer		--bCustomer	null
,	ARTransType		--CHAR(1)		NULL
,	Invoice			--VARCHAR(10)	NULL 
,	InvoiceDesc		--bDesc		NULL 
,	InvAmountDue	--bDollar		NULL
,	Amount			--bDollar		NULL
,	DiscOffered		--bDollar		NULL
,	Retainage		--bDollar		NULL
,	DueDate			--bDate		NULL
,	AgeDate			--bDate		NULL
,	DaysFromAge		--INT			NULL
,	AgeAmount		--bDollar		NULL 
,	DueCurrent		--bDollar		NULL 
,	Due30to60		--bDollar		NULL 
,	Due60to90		--bDollar		NULL 
,	Due90to120		--bDollar		NULL 
,	Due120Plus		--bDollar		NULL 
,	CheckNo			--VARCHAR(10)	NULL
,	LongCheckNo		--VARCHAR(20)	NULL
,	CheckDate		--bDate		NULL
,	GLCo			--bCompany	NULL
,	GLAcct			--bGLAcct		NULL
,	JCCo			--bCompany	NULL 
,	Contract		--bContract	NULL
,	Item			--bContractItem		NULL 
,	Job				--bJob		NULL 
,	SMCo			--bCompany	NULL
,	WorkOrder		--bWO			null
,	ApplyMth		--bMonth		NULL
,	ApplyTrans		--bTrans		NULL
)
SELECT 
	arth.ARCo
,	arth.Mth
,	arth.ARTrans
,	arth.CustGroup
,	arth.Customer
,	arth.ARTransType
,	ar_txn.Invoice
,	ar_txn.InvoiceDesc
,	ar_txn.AmountDue
,	SUM(artl.Amount) AS Amount
,	SUM(artl.DiscOffered) AS DiscOffered
,	SUM(artl.Retainage) AS Retainage
,	ar_txn.DueDate
,	CASE ar_txn.AmountDue
		WHEN 0 THEN NULL
		else isnull(arth.DueDate,arth.TransDate) 
	end AS AgeDate
,	CASE ar_txn.AmountDue
		WHEN 0 THEN NULL
		ELSE DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) 
	END AS DaysFromAge
,	CASE ar_txn.AmountDue	
		WHEN 0 THEN 0
		ELSE SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage) 
	END AS AgeAmount
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) < 30 AND ar_txn.AmountDue <> 0 THEN SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage) 
		ELSE 0
	END AS DueCurrent
,	CASE
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 30 and 60 AND ar_txn.AmountDue <> 0 THEN SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage)
		ELSE 0
	END AS Due30to60
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 61 and 90 AND ar_txn.AmountDue <> 0  THEN SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage)
		ELSE 0
	END AS Due60to90
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) between 91 and 120 AND ar_txn.AmountDue <> 0  THEN SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage) 
		ELSE 0
	END AS Due90to120
,	CASE 
		WHEN DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate) > 120 AND ar_txn.AmountDue <> 0  THEN SUM(artl.Amount)-SUM(artl.DiscOffered)-SUM(artl.Retainage) 
		ELSE 0
	END AS Due120Plus
,	arth.CheckNo
,	arth.udCheckNo AS LongCheckNo
,	arth.CheckDate
,	ar_txn.GLCo
,	ar_txn.GLAcct
,	ar_txn.JCCo
,	ar_txn.Contract
,	ar_txn.Item
,	ar_txn.Job
,	ar_txn.udSMCo
,	ar_txn.udWorkOrder
,	ar_txn.ApplyMth
,	ar_txn.ApplyTrans
FROM 
	ar_txn ar_txn 
JOIN ARTL artl ON 
	artl.ARCo=ar_txn.ARCo 
AND artl.ApplyMth=ar_txn.ApplyMth
AND artl.ApplyTrans=ar_txn.ApplyTrans
AND artl.ApplyLine = ar_txn.ApplyLine
JOIN ARTH arth ON
	artl.ARCo=arth.ARCo
AND artl.Mth=arth.Mth	
AND artl.ARTrans=arth.ARTrans
GROUP BY
	arth.ARCo
,	arth.Mth
,	arth.ARTrans
,	arth.CustGroup
,	arth.Customer
,	ar_txn.GLCo
,	ar_txn.GLAcct
,	ar_txn.JCCo
,	ar_txn.Contract
,	ar_txn.Item
,	ar_txn.Job
,	ar_txn.udSMCo
,	ar_txn.udWorkOrder
,	ar_txn.Invoice
,	ar_txn.InvoiceDesc
,	arth.ARTransType
,	isnull(arth.DueDate,arth.TransDate)
,	DATEDIFF(day,isnull(arth.DueDate,arth.TransDate), @AgeDate)
,	ar_txn.DueDate
,	ar_txn.AmountDue
,	arth.CheckNo
,	arth.udCheckNo 
,	arth.CheckDate
,	ar_txn.ApplyMth
,	ar_txn.ApplyTrans
ORDER BY
	arth.ARCo
,	arth.CustGroup
,	arth.Customer
,	ar_txn.JCCo
,	ar_txn.Contract
,	ar_txn.Invoice;

RETURN
END
go


DECLARE @ARCo bCompany		
DECLARE @Customer bCustomer
DECLARE @Contract bContract	
DECLARE @Invoice VARCHAR(10)
DECLARE @AgeDate bDate		

--SET @ARCo=1 
--SET @Contract=' 10204-'
--SET @Invoice='     55020' 
--SET @Invoice='     52184'
--SET @Invoice='     64894'
--SET @Invoice='  20008913'
	SET @AgeDate = '4/1/2015'
	SET @Customer=202172
	SET @ARCo=1

	SELECT * FROM  mers.mfnARDetail_temp(@ARCo,@Customer,@Contract,@Invoice,@AgeDate)



DECLARE @ARCo bCompany		
DECLARE @Customer bCustomer
DECLARE @Contract bContract	
DECLARE @Invoice VARCHAR(10)
DECLARE @AgeDate bDate		

SET @ARCo=1
SET @AgeDate = '3/1/2015'
SET @Customer=209135
SET @Invoice='0430415'

SELECT * FROM  mers.mfnARDetail_temp(@ARCo,@Customer,@Contract,@Invoice,@AgeDate) ORDER BY Invoice


select * FROM ARTH WHERE Invoice='0430415'
