SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[mvwRLBAPSLExport]

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

GO
