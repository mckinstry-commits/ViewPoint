use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mckfnPOMaster' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION dbo.mckfnPOMaster'
	DROP FUNCTION dbo.mckfnPOMaster
end
go

print 'CREATE FUNCTION dbo.mckfnPOMaster'
go

CREATE FUNCTION [dbo].[mckfnPOMaster]
(
	@Job		bJob 
)
-- ========================================================================
-- Object Name: dbo.mckfnPOMaster
-- Author:		Ziebell, Jonathan
-- Create date: 03/22/2017
-- Description: 
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell	03/22/2017 Initial Build
--				J.Ziebell	05/24/2017 Update for Missing SMWorkOrders
--				J.Ziebell	05/31/2017 New update Round
--				J.Ziebell   06/08/2017 Add Work Orders
-- ========================================================================

RETURNS @retTable TABLE
(
	[PO Req #] [varchar](30) NOT NULL,
	[McK PO] [varchar](30) NULL,
	[Description] [dbo].[bItemDesc] NULL,
	[Item Count] [smallint] NULL,
	[Vendor] [dbo].[bVendor] NOT NULL,
	[Vendor Name] [varchar](60) NULL,
	[PO Status] [varchar](13) NULL,
	[PO Amount] [dbo].[bDollar] NOT NULL,
	[Invoiced] [dbo].[bDollar] NOT NULL,
	[Paid] [dbo].[bDollar] NOT NULL,
	[Current Due] [dbo].[bDollar] NOT NULL,
	[Remaining Committed] [dbo].[bDollar] NULL,
	[Overspend] [dbo].[bDollar] NULL,
	[Phase Code] [dbo].[bPhase] NULL,
	[Phase Code Description] [dbo].[bItemDesc] NULL,
	[Cost Type] [varchar](1) NULL,
	[WO #] [int] NULL,
	[Work Order Description] [varchar](255) NULL,
	[Ordered By] [int] NULL,
	[Ordered By Name] [varchar](62) NULL,
	[Order Date] [dbo].[bDate] NULL
	)

BEGIN
	WITH PO_Cost_Sum AS (SELECT PV.POCo
							, PV.PO
							, PV.VendorGroup
							, PV.Vendor
							, PV.JCCo
							--, PV.ItemDesc
							--, ISNULL(PV.Job,WO.Job) AS Job
							, PV.Job AS Job
							, PV.PhaseGroup
							, PV.Phase
							, PV.JCCType AS CostType
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
							, SUM(CASE WHEN ((PV.Status = 2) OR (PV.CurCost=0)) THEN 0 
										WHEN PV. InvCost > PV.CurCost THEN 0 
										ELSE CASE TaxType 
											WHEN 1 THEN (PV.CurCost - PV.InvCost)
											WHEN 3 THEN (PV.CurCost - PV.InvCost + InvCostTax - JCCmtdTax)
											ELSE PV.CurCost - InvCost + InvCostTax END  END) AS 'RemainCommit'
							, SUM(CASE TaxType 
										WHEN 1 THEN InvCost - PV.APPaidAmt
										WHEN 3 THEN (InvCost - InvCostTax + JCCmtdTax - PV.APPaidAmt)
										ELSE InvCost - InvCostTax - PV.APPaidAmt END) AS 'CurrentDue'
							--, 't' as Overspend
					FROM mrvPOCurCostByVendor3 PV
					WHERE PV.Job= @Job 
					GROUP BY PV.POCo
							, PV.PO
							, PV.VendorGroup
							, PV.Vendor
							, PV.JCCo
							--, PV.POItem
							--, PV.ItemDesc
							, PV.Job
							--, WO.Job
							, PV.PhaseGroup
							, PV.Phase
							, PV.JCCType)
	INSERT @retTable
           ([PO Req #] 
           ,[McK PO]
		   ,[Description]
		   ,[Item Count]
           ,[Vendor]
           ,[Vendor Name]
		   ,[PO Status]
		   ,[PO Amount]
		   ,[Invoiced] 
		   ,[Paid]
		   ,[Current Due] 
		   ,[Remaining Committed]
		   ,[Overspend]
		   ,[Phase Code]
		   ,[Phase Code Description]
		   ,[Cost Type]
		   ,[WO #] 
		   ,[Work Order Description]
           ,[Ordered By]
           ,[Ordered By Name]
           ,[Order Date]
		   )
	SELECT PS.PO
	,	HD.udMCKPONumber AS McKPO
	,	HD.Description AS POItemDesc
	,   PS.POItemCount AS ItemCount
	,	PS.Vendor
	,	VM.Name AS VendorName
	,	CASE HD.Status
			WHEN 0 THEN '0-Open'
			WHEN 1 THEN '1-Complete'
			WHEN 2 THEN '2-Closed'
			ELSE CAST(HD.Status AS VARCHAR(5)) + '-Unknown'
				END AS POStatus
	,	PS.CurCost
	,	PS.InvCost
	,	PS.APPaidAmt
	,	PS.CurrentDue
	,	PS.RemainCommit
	,   CASE WHEN PS.InvCost <=0 THEN 0
			WHEN PS.InvCost > PS.CurCost THEN (PS.InvCost -  PS.CurCost) 
			ELSE 0 END AS Overspend
	,	PS.Phase
	,	jcjp.Description AS PhaseDesc
	,   CT.Abbreviation AS 'Cost Type'
	--,   PS.CostType
	,	IT.SMWorkOrder
	,	smwo.Description AS SMWODescritpion 
	,	HD.udOrderedBy
	,	CASE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'') 
			WHEN '' THEN NULL
			ELSE COALESCE(pmpm.LastName + ', ','') +  COALESCE(pmpm.FirstName,'')
				END AS OrderedByName
	,	HD.OrderDate
	FROM PO_Cost_Sum PS
		INNER JOIN POHD HD
			ON HD.POCo = PS.POCo
				AND HD.PO = PS.PO
				--AND HD.JCCo = PS.JCCo
				--AND HD.Job = PS.Job
		INNER JOIN POIT IT 
			ON PS.POCo = IT.POCo
				AND PS.PO = IT.PO
				AND PS.POItem = IT.POItem
		INNER JOIN APVM VM
			ON PS.VendorGroup = VM.VendorGroup
				AND PS.Vendor = VM.Vendor
		INNER JOIN	JCCT CT 
			ON PS.PhaseGroup = CT.PhaseGroup
				AND PS.CostType = CT.CostType 
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
		WHERE PS.Job = @Job

RETURN

END

GO

Grant select on dbo.mckfnPOMaster  to [MCKINSTRY\Viewpoint Users]







