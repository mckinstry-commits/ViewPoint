SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[mvwRLBAPPOExport]

as

/*
2014.06.03 - LWO - Removed Remaining Balance restriction as per conversation
                   with EB, GG, SC & HS
*/
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
--HAVING
--	(SUM(POIT.RemCost) <> 0 OR SUM(POIT.RemTax) <> 0 )
UNION
SELECT 
	POHD.POCo AS Company
,	POHD.udMCKPONumber AS PurchaseOrderNumber
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
,	POHD.udMCKPONumber
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
--HAVING
--	(SUM(POIT.RemCost) <> 0 OR SUM(POIT.RemTax) <> 0 )
GO
