
use Viewpoint
go

if exists ( select 1 from sysobjects where type='V' and name='mvwRLBARExport')
begin
	print 'Drop view mvwRLBARExport'
	drop view mvwRLBARExport
end
go

if exists ( select 1 from sysobjects where type='V' and name='mvwRLBAPPOExport')
begin
	print 'Drop view mvwRLBAPPOExport'
	drop view mvwRLBAPPOExport
end
go

if exists ( select 1 from sysobjects where type='V' and name='mvwRLBAPSLExport')
begin
	print 'Drop view mvwRLBAPSLExport'
	drop view mvwRLBAPSLExport
end
go

if exists ( select 1 from sysobjects where type='V' and name='mvwRLBAPExport')
begin
	print 'Drop view mvwRLBAPExport'
	drop view mvwRLBAPExport
end
go

print 'Create view mckvw_Gen_RLB_AR_Header_Export'
go

create view mvwRLBARExport
as
SELECT
	ARTH.ARCo AS Company
,	ARTH.Invoice AS InvoiceNumber
,	ARTH.CustGroup
,	ARTH.Customer 
,	ARCM.Name AS CustomerName
,	ARTH.TransDate AS TransactionDate
--,	ARTL.Mth
--,	ARTL.ARTrans
,	ARTH.Description AS InvoiceDescription
--,	MAX(ARTL.Description) AS MaxLineDesc
,	COUNT(ARTL.KeyID) AS DetailLineCount
,	COALESCE(ARTH.AmountDue,0.00) AS AmountDue
,	COALESCE(SUM(ARTL.Amount),0) AS OriginalAmount
--,	SUM(ARTL.Amount) AS AmountSum
--,	SUM(ARTL.TaxBasis) AS TaxBasisSum
--,	SUM(ARTL.TaxAmount) AS AmountTaxSum
--,	SUM(ARTL.TaxDisc) AS TaxDiscountSum
--,	SUM(ARTL.DiscOffered) AS DiscountOfferedSum
--,	SUM(ARTL.DiscTaken) AS DiscountTakenSum
--,	SUM(ARTL.FinanceChg) AS FinanceChgSum
--,	SUM(ARTL.Retainage) AS RetainageSum
--,	SUM(ARTL.RetgTax) AS RetainageTaxSum
--,	COALESCE(SUM(ARTL.Amount),0) AS Amount
,	COALESCE(SUM(ARTL.TaxAmount),0) AS Tax
--,	COALESCE(SUM(ARTL.Retainage),0) AS Retainage
--,	COALESCE((SUM(ARTL.Amount)-SUM(ARTL.Retainage)),0) AS Total
from 
	dbo.HQCO HQCO  INNER JOIN
	dbo.ARTH ARTH ON
		HQCO.HQCo=ARTH.ARCo LEFT OUTER JOIN 
	dbo.ARTL ARTL ON
		ARTL.ARCo=ARTH.ARCo
		AND ARTL.Mth=ARTH.Mth			 
		AND ARTL.ARTrans=ARTH.ARTrans INNER JOIN 
	dbo.ARCM ARCM ON 
		ARTH.CustGroup=ARCM.CustGroup
	AND ARTH.Customer=ARCM.Customer
WHERE
	ARTH.AmountDue <> 0
--	HQCO.HQCo=101
--	(ARTH.Invoice>=' ' AND ARTH.Invoice<='zzzzzzzzzz')
--AND	ARTH.TransDate>={ts '2013-01-01 00:00:00'} 
GROUP BY
	ARTH.ARCo
,	ARTH.Invoice 
,	ARTH.TransDate 
--,	ARTL.Mth
--,	ARTL.ARTrans
,	ARTH.CustGroup
,	ARTH.Customer 
,	ARCM.Name
,	ARTH.Description 
,	ARTH.AmountDue 
--ORDER BY
--	ARTH.Invoice
go

--SELECT * FROM mvwRLBARExport

print 'Create view mckvw_Gen_RLB_AP_PO_Header_Export'
go

CREATE VIEW mvwRLBAPPOExport

as

SELECT 
	POHD.POCo AS Company
,	POHD.PO AS PurchaseOrderNumber
--,	isnull(POHD.Description,'No Description') as "Description"
,	POHD.VendorGroup
,	POHD.Vendor
,	APVM.Name AS VendorName
,	POHD.OrderDate AS TransactionDate
--,	POHD.OrderedBy
--,	POHD.Status
--,	POHD.Approved
--,	POHD.ApprovedBy	
,	POHD.JCCo
,	POHD.Job
,	JCJM.Description AS JobDescription
,	isnull(POHD.Description,'No Description') as "PurchaseOrderDescription"
,	COUNT(POIT.KeyID) AS DetailLineCount										-- why include Status if must be 0?
,	SUM(POIT.OrigCost) AS TotalOrigCost
,	SUM(POIT.OrigTax) AS TotalOrigTax
--,	SUM(POIT.CurCost) AS TotalCurCost
--,	SUM(POIT.CurTax) AS TotalCurTax
--,	SUM(POIT.TotalCost) AS TotalCost
--,	SUM(POIT.TotalTax) AS TotalTax
,	SUM(POIT.RemCost) AS RemainingAmount
,	SUM(POIT.RemTax) AS RemainingTax
FROM 
	POHD with (nolock) INNER JOIN 
	APVM with (nolock) ON 
		POHD.VendorGroup = APVM.VendorGroup
	and POHD.Vendor = APVM.Vendor LEFT OUTER JOIN
	POIT with (nolock) ON
		POHD.POCo=POIT.POCo
	AND POHD.PO=POIT.PO LEFT OUTER  JOIN 
		JCJM JCJM ON 
			(POHD.JCCo=JCJM.JCCo) 
		AND (POHD.Job=JCJM.Job)
WHERE 
	POHD.Status=0
GROUP BY
	POHD.POCo
,	POHD.PO
--,	isnull(POHD.Description,'No Description') 
,	POHD.Vendor
,	APVM.Name 
,	POHD.OrderDate
,	POHD.JCCo
,	POHD.Job
,	JCJM.Description
,	POHD.Description
--,	POHD.OrderedBy
--,	POHD.Status
,	POHD.VendorGroup	
--,	POHD.Approved
--,	POHD.ApprovedBy	
HAVING
	(SUM(POIT.RemCost) <> 0 OR SUM(POIT.RemTax) <> 0 )
GO

--SELECT * FROM  mvwRLBAPPOExport

print 'Create view mvwRLBAPSLExport'
go

CREATE VIEW mvwRLBAPSLExport

as

 SELECT 
--	HQCO.HQCo AS Company
--,	HQCO.Name
	SLHD.SLCo  AS Company
,	SLHD.SL AS SubcontractNumber
,	SLHD.VendorGroup
,	SLHD.Vendor
,	APVM.Name AS VendorName
,	SLHD.OrigDate AS TransactionDate
,	SLHD.JCCo
,	SLHD.Job
,	JCJM.Description AS JobDescription
,	isnull(SLHD.Description,'No Description') as "SubcontractDescription"
,	COUNT(vrvPMSubScoItem.SLItem) AS DetailLineCount
,	SUM(vrvPMSubScoItem.OrigCost) AS SLOriginalCost
,   0 AS SLOriginalTax
,	SUM(vrvPMSubScoItem.Amount) AS Amount
,   0 AS Tax

--,	vrvPMSubScoItem.SubCO
--,	vrvPMSubScoItem.Description
--,	vrvPMSubScoItem.Seq
--,	vrvPMSubScoItem.SL
--,	vrvPMSubScoItem.PMCo
--,	vrvPMSubScoItem.OrigCost
--,	vrvPMSubScoItem.Amount
--,	vrvPMSubScoItem.MinSeq
--,	vrvPMSubScoItem.RecordType
--,	vrvPMSubScoItem.SLItemType
--,	vrvPMSubScoItem.ApprovedDate
--,	vrvPMSubScoItem.Project
--,	vrvPMSubScoItem.ACO
--,	vrvPMSubScoItem.SLDescription
--,	JCJM.JCCo
--,	vrvPMSubScoItem.SLItem
--,	vrvPMSubScoItem.InterfaceDate
--,	vrvPMSubScoItem.SLItemDescription
--,	vrvPMSubScoItem.SubCODescription
--,	'          '
 FROM   
	(
		(
			vrvPMSubScoItem vrvPMSubScoItem INNER JOIN 
			HQCO HQCO ON 
				vrvPMSubScoItem.PMCo=HQCO.HQCo
		) INNER JOIN 
		JCJM JCJM ON 
			(vrvPMSubScoItem.PMCo=JCJM.JCCo) 
		AND (vrvPMSubScoItem.Project=JCJM.Job)) LEFT OUTER JOIN 
		SLHD SLHD ON 
			(vrvPMSubScoItem.SLCo=SLHD.SLCo) 
		AND (vrvPMSubScoItem.SL=SLHD.SL) LEFT OUTER  JOIN 
	APVM with (nolock) ON 
		SLHD.VendorGroup = APVM.VendorGroup
	and SLHD.Vendor = APVM.Vendor
 WHERE  
	vrvPMSubScoItem.SL IS  NOT  NULL  
--AND vrvPMSubScoItem.PMCo=101 
AND (
	vrvPMSubScoItem.Project='' 
OR '          '=''
	) 
--AND (
--		vrvPMSubScoItem.SL>=' ' 
--	AND vrvPMSubScoItem.SL<='zzzzzzzzzz'
--	)
AND vrvPMSubScoItem.InterfaceDate is NOT NULL
GROUP BY
--	HQCO.HQCo
--,	HQCO.Name
	SLHD.SLCo
,	SLHD.SL
,	SLHD.VendorGroup
,	SLHD.Vendor
,	APVM.Name
,	SLHD.OrigDate
,	SLHD.JCCo
,	SLHD.Job
,	JCJM.Description
,	SLHD.Description
HAVING
	SUM(vrvPMSubScoItem.Amount) <> 0
--	SUM(vrvPMSubScoItem.OrigCost) <> SUM(vrvPMSubScoItem.Amount)
--ORDER BY 
--	SLHD.JCCo
--,	SLHD.Job
--, SLHD.SL

go


--SELECT * FROM mvwRLBAPSLExport 
go

CREATE VIEW mvwRLBAPExport
as

SELECT 
	'PO' AS RecordType
,	[Company]
,	[PurchaseOrderNumber] AS Number
,	[VendorGroup]
,	[Vendor]
,	[VendorName]
,	[TransactionDate]
,	[JCCo]
,	[Job]
,	[JobDescription]
,	[PurchaseOrderDescription] AS Description
,	[DetailLineCount]
,	[TotalOrigCost]
,	[TotalOrigTax]
,	[RemainingAmount]
,	[RemainingTax]
FROM 
	mvwRLBAPPOExport
UNION
SELECT 
	'SC' AS RecordType
,	[Company]
,	[SubcontractNumber]
,	[VendorGroup]
,	[Vendor]
,	[VendorName]
,	[TransactionDate]
,	[JCCo]
,	[Job]
,	[JobDescription]
,	[SubcontractDescription]
,	[DetailLineCount]
,	[SLOriginalCost]
,	[SLOriginalTax]
,	[Amount]
,	[Tax]
FROM 
	mvwRLBAPSLExport

go

select * from mvwRLBARExport
select * from mvwRLBAPPOExport
select * from mvwRLBAPSLExport
select * from mvwRLBAPExport
