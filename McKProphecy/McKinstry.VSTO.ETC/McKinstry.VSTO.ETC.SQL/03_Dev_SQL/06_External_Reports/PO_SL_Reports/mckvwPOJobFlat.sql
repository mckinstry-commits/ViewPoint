use Viewpoint
go

CREATE VIEW [dbo].[mckvwPOJobFlat] AS
-- ========================================================================
-- Object Name: dbo.mckvwPOJobFlat
-- Author:		Ziebell, Jonathan
-- Create date: 06/13/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
WITH POCostSum AS (SELECT	  PV.POCo AS JCCo
							, PV.PO
							, PV.VendorGroup
							, PV.Vendor
							, PV.Job AS Job
							, PV.PhaseGroup
							, PV.Phase
							, PV.JCCType AS CostType
							, MAX(PV.Status) AS Status
							, MIN(PV.POItem) AS POItem
							, SUM(CASE WHEN PV.RecType='PO' THEN 1 ELSE 0 END) AS POItemCount
							, MAX(TaxType) AS TaxType
							, SUM(CurCost) AS CurCost
							, SUM(CurTax) AS CurTax
							, SUM(CASE TaxType 
										WHEN 1 THEN InvCost 
										WHEN 3 THEN (InvCost - InvCostTax + JCCmtdTax)
										ELSE InvCost - InvCostTax END) AS InvCost
							, SUM(InvCostTax) AS InvCostTax
							, SUM(PV.APPaidAmt) AS 'APPaidAmt'
							, SUM(PV.APTaxAmount) AS 'APTaxAmount'
							, SUM(PV.APTotTaxAmount) AS 'APTotTaxAmount' 
							, SUM(PV.APJCCommittedVATtax) AS 'APJCCommittedVATtax'
							, SUM(PV.JCCmtdTax) AS JCCmtdTax
							, SUM(CASE TaxType 
										WHEN 1 THEN InvCost - PV.APPaidAmt
										WHEN 3 THEN (InvCost - InvCostTax + JCCmtdTax - PV.APPaidAmt)
										ELSE InvCost - InvCostTax - PV.APPaidAmt END) AS 'CurrentDue'
					FROM mrvPOCurCostByVendor3 PV
					GROUP BY PV.POCo
							, PV.PO
							, PV.VendorGroup
							, PV.Vendor
							, PV.Job
							, PV.PhaseGroup
							, PV.Phase
							, PV.JCCType)
							--, PV.Status)
SELECT  PS.JCCo
	, PS.PO
	, PS.VendorGroup
	, PS.Vendor
	, PS.Job
	, PS.PhaseGroup
	, PS.Phase
	, PS.CostType
	, PS.Status
	, HD.udMCKPONumber AS McKPO
	, HD.Description AS POItemDesc
	, PS.POItemCount AS ItemCount
	, VM.Name AS VendorName
	, CASE PS.Status
			WHEN 0 THEN '0-Open'
			WHEN 1 THEN '1-Complete'
			WHEN 2 THEN '2-Closed'
			ELSE CAST(HD.Status AS VARCHAR(5)) + '-Unknown'
				END AS POStatus
	, PS.CurCost
	, PS.InvCost
	, PS.APPaidAmt
	, PS.CurrentDue
	, CASE WHEN ((PS.Status = 2) OR (PS.CurCost <= 0)) THEN 0 
			WHEN ((PS.TaxType = 1) AND (PS.InvCost <= PS.CurCost)) THEN (PS.CurCost - PS.InvCost)
			WHEN ((PS.TaxType = 3) AND ((PS.InvCost + PS.InvCostTax) <= (PS.CurCost + PS.JCCmtdTax))) THEN (PS.CurCost - PS.InvCost + PS.InvCostTax - PS.JCCmtdTax)
			WHEN ((PS.InvCost) <= (PS.CurCost + InvCostTax)) THEN (PS.CurCost - PS.InvCost + InvCostTax) 
			ELSE 0 END AS 'RemainCommit'
	,   CASE WHEN PS.InvCost <=0 THEN 0
			WHEN PS.InvCost > PS.CurCost THEN (PS.InvCost -  PS.CurCost) 
			ELSE 0 END AS Overspend
	,	jcjp.Description AS PhaseDesc
	--,   CT.Abbreviation AS 'CostType'
	--,   PS.CostType
	,	IT.SMWorkOrder
	,	smwo.Description AS SMWODescritpion 
	,	HD.udOrderedBy
	,	CASE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'') 
			WHEN '' THEN NULL
			ELSE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'')
				END AS OrderedByName
	,	HD.OrderDate
	FROM POCostSum PS
		INNER JOIN POHD HD
			ON HD.POCo = PS.JCCo
				AND HD.PO = PS.PO
				--AND HD.JCCo = PS.JCCo
				--AND HD.Job = PS.Job
		INNER JOIN POIT IT 
			ON PS.JCCo = IT.POCo
				AND PS.PO = IT.PO
				AND PS.POItem = IT.POItem
		INNER JOIN APVM VM
			ON PS.VendorGroup = VM.VendorGroup
				AND PS.Vendor = VM.Vendor
		--INNER JOIN	JCCT CT 
		--	ON PS.PhaseGroup = CT.PhaseGroup
		--		AND PS.CostType = CT.CostType 
		LEFT OUTER JOIN JCJP jcjp 
			ON PS.JCCo=jcjp.JCCo
				AND PS.Job=jcjp.Job
				AND PS.PhaseGroup=jcjp.PhaseGroup
				AND PS.Phase = jcjp.Phase
		LEFT OUTER JOIN SMWorkCompleted smwo_wc 
			ON IT.SMCo=smwo_wc.SMCo
				AND IT.SMWorkOrder=smwo_wc.WorkOrder
				AND IT.SMScope=smwo_wc.Scope
				AND IT.POItem=smwo_wc.POItem
				AND IT.POCo=smwo_wc.POCo
				AND IT.PO=smwo_wc.PO
		LEFT OUTER JOIN SMWorkOrder smwo 
			ON smwo_wc.SMCo=smwo.SMCo
				AND smwo_wc.WorkOrder=smwo.WorkOrder
		LEFT OUTER JOIN PMPM1 pmpm 
			ON HD.udOrderedBy=pmpm.ContactCode
				AND HD.VendorGroup=pmpm.VendorGroup
				AND pmpm.FirmNumber =  (SELECT TOP 1 PMCO.OurFirm FROM PMCO WHERE PMCo = HD.POCo) 
				AND pmpm.ExcludeYN <> 'Y' 

 GO

 Grant SELECT ON dbo.mckvwPOJobFlat TO [MCKINSTRY\Viewpoint Users]