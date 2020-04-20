SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[vrvSMWorkOrderTotalsByLineType] 
as

/***********************************************************************
*	Created: 10/10/11
*	Author : Dan Koslicki
*	Purpose: This view rolls up Work Completed Line Types (Labor, Parts, 
*	Equip, Other) and pivots them so they are persisted columnar data 
* 
*	Reports: SMInvoice.rpt
* 
* 
*	MOD: 10/17/11 - DK
*	Reason: Changed logic to include all invoices and include cost amounts
*			also added logic to include full cost and not exclude No Charge items
* 
*	MOD: 10/24/11 - DK
*	Reason: Changed logic of WO Cost Total to use Cost and not Price columns
*			Also alter Cost Logic to use ProjCost when ActualCost IS NULL OR = 0
*   MOD: 06/04/13 - ScottAlvey TFS-44858 Change AR Batch creation and posting for SM Invoices
		SMInvoiceID in SMWorkCompleted is being dropped, removed references and relinked views
***********************************************************************/


-- First we need to select and convert the Work Completed line types to 
-- columnar data. This is done via Pivot. This CTE excludes no charge items
WITH cteSMWCTypePivotPrice 
AS 

	(SELECT			SMCo,
					WorkOrder,
					Invoice,
					SMInvoiceID,
					Scope,
					[1]	AS Equip,
					[2]	AS Labor,
					[3]	AS Other,
					[4]	AS Parts,
					[5] as Purch,
					TaxAmount

	FROM			(SELECT			SMWC.SMCo				AS SMCo,
									SMWC.WorkOrder			AS WorkOrder, 
									SMWC.Invoice			AS Invoice,
									SMIN.SMInvoiceID		as SMInvoiceID,
									SMWC.Scope				AS Scope, 
									SMWC.Type				AS Type, 
									SMWC.NoCharge			AS NoCharge,
									SUM(SMWC.PriceTotal)	AS PriceTotal,
									SUM(SMWC.TaxAmount)		AS TaxAmount
					
					 FROM			SMWorkCompleted				SMWC
					 JOIN			SMInvoiceList				SMIN ON
									SMWC.SMCo = SMIN.SMCo AND SMWC.Invoice = SMIN.Invoice

					 WHERE			SMWC.NoCharge = 'N'

					 GROUP BY		SMWC.SMCo,
									SMWC.WorkOrder, 
									SMWC.Invoice,
									SMIN.SMInvoiceID,
									SMWC.Scope, 
									SMWC.Type, 
									SMWC.NoCharge) AS A 
									
					PIVOT (SUM(PriceTotal) FOR "Type" IN ([1],[2],[3],[4],[5])) AS PPrice),


-- again, pivot data, this time for the Cost Totals. This CTE includes cost regardless of 
-- the No Charge Flag.				
cteSMWCTypePivotCost	
AS
	(SELECT			SMCo,
					WorkOrder,
					Invoice,
					SMInvoiceID,
					Scope,
					Equip,
					Labor,
					Other,
					Parts,
					Purch,
					TaxAmount,
					[1]			AS EquipCost,
					[2]			AS LaborCost,
					[3]			AS OtherCost,
					[4]			AS PartsCost,
					[5]			AS PurchCost

	FROM			(SELECT			SMWC.SMCo				AS SMCo,
									SMWC.WorkOrder			AS WorkOrder, 
									SMWC.Invoice			AS Invoice,
									SMIN.SMInvoiceID		as SMInvoiceID,
									SMWC.Scope				AS Scope, 
									SMWC.Type				AS Type,
									CSMPP.Equip				AS Equip,
									CSMPP.Labor				AS Labor,
									CSMPP.Other				AS Other,
									CSMPP.Parts				AS Parts,
									CSMPP.Purch				AS Purch,
									CSMPP.TaxAmount			AS TaxAmount, 
									SUM(
											CASE WHEN SMWC.ActualCost IS NULL OR SMWC.ActualCost = 0 THEN SMWC.ProjCost ELSE SMWC.ActualCost
											END
										)					AS TotalCost
					
					 FROM			SMWorkCompleted				SMWC
					 JOIN			SMInvoiceList				SMIN ON
									SMWC.SMCo = SMIN.SMCo AND SMWC.Invoice = SMIN.Invoice
					 
					 LEFT OUTER JOIN	cteSMWCTypePivotPrice	AS CSMPP
								ON	CSMPP.SMCo			= SMWC.SMCo
								AND CSMPP.Invoice		= SMWC.Invoice
								AND	CSMPP.WorkOrder		= SMWC.WorkOrder
								AND CSMPP.Scope			= SMWC.Scope 
					 
					 GROUP BY		SMWC.SMCo,
									SMWC.WorkOrder, 
									SMWC.Invoice,
									SMIN.SMInvoiceID,
									SMWC.Scope, 
									SMWC.Type,
									CSMPP.Equip,
									CSMPP.Labor,
									CSMPP.Other,
									CSMPP.Parts,
									CSMPP.Purch,
									CSMPP.TaxAmount) AS B 
	
	
									
					PIVOT (SUM(TotalCost) FOR "Type" IN ([1],[2],[3],[4],[5])) AS PCost),


-- rollup data by scope	- WITH ROLLUP performs aggregation by the several possible 
-- grouping options so that we can simply select the values we want from the calculated data
cteSMWWCRollupToScope
AS 
	(SELECT			SMCo,
					Invoice,
					SMInvoiceID,
					WorkOrder,
					Scope, 
					SUM(Equip)		AS Equip, 
					SUM(Labor)		AS Labor, 
					SUM(Parts)		AS Parts,	
					SUM(Other)		AS Other,
					SUM(Purch)		AS Purch,
					SUM(TaxAmount)	AS TaxAmount,
					SUM(EquipCost)	AS EquipCost, 
					SUM(LaborCost)	AS LaborCost, 
					SUM(PartsCost)	AS PartsCost,	
					SUM(OtherCost)	AS OtherCost,
					SUM(PurchCost)	AS PurchCost

	FROM cteSMWCTypePivotCost 

	GROUP BY		SMCo,
					Invoice,
					SMInvoiceID,
					WorkOrder,
					Scope

	WITH ROLLUP)
	

	
SELECT				RTS.SMCo,
					RTS.Invoice,
					RTS.SMInvoiceID,
					RTS.WorkOrder,
					RTS.Scope,
					RTS.Equip		AS ScopeEquipTotal,
					RTS.Labor		AS ScopeLaborTotal,
					RTS.Parts		AS ScopePartsTotal,
					RTS.Other		AS ScopeOtherTotal,
					RTS.Purch		AS ScopePurchTotal,
					RTS.TaxAmount	AS ScopeTaxAmtTotal,	
					ISNULL(RTS.Equip,0) + ISNULL(RTS.Labor,0) + ISNULL(RTS.Parts,0) + 
						ISNULL(RTS.Other,0) + ISNULL(RTS.Purch,0) AS ScopeTotal,
					RTWO.Equip		AS WOEquipTotal,
					RTWO.Labor		AS WOLaborTotal,
					RTWO.Parts		AS WOPartsTotal,
					RTWO.Other		AS WOOtherTotal,
					RTWO.Purch		AS WOPurchTotal,
					RTWO.TaxAmount	AS WOTaxAmtTotal,
					ISNULL(RTWO.Equip,0) + ISNULL(RTWO.Labor,0) + ISNULL(RTWO.Parts,0) + 
						ISNULL(RTWO.Other,0) + ISNULL(RTWO.Purch,0) AS WOTotal,
					RTS.EquipCost	AS ScopeEquipCostTotal,
					RTS.LaborCost	AS ScopeLaborCostTotal,
					RTS.PartsCost	AS ScopePartsCostTotal,
					RTS.OtherCost	AS ScopeOtherCostTotal,
					RTS.PurchCost	AS ScopePurchCostTotal,
					ISNULL(RTS.EquipCost,0) + ISNULL(RTS.LaborCost,0) + ISNULL(RTS.PartsCost,0) + 
						ISNULL(RTS.OtherCost,0) + ISNULL(RTS.PurchCost,0) AS ScopeCostTotal,
					RTWO.EquipCost		AS WOEquipCostTotal,
					RTWO.LaborCost		AS WOLaborCostTotal,
					RTWO.PartsCost		AS WOPartsCostTotal,
					RTWO.OtherCost		AS WOOtherCostTotal,
					RTWO.PurchCost		AS WOPurchCostTotal,
					ISNULL(RTWO.EquipCost,0) + ISNULL(RTWO.LaborCost,0) + ISNULL(RTWO.PartsCost,0) + 
						ISNULL(RTWO.OtherCost,0) + ISNULL(RTWO.PurchCost,0) AS WOCostTotal
					

FROM				cteSMWWCRollupToScope RTS

-- join the cte to itself to collect up the Work Order totals for each Invoice
LEFT OUTER JOIN		cteSMWWCRollupToScope RTWO
				ON	RTWO.SMCo			= RTS.SMCo
				AND RTWO.Invoice		= RTS.Invoice
				AND RTWO.WorkOrder		= RTS.WorkOrder
				AND RTWO.WorkOrder IS NOT NULL
				AND RTWO.Scope IS NULL 

WHERE				RTS.Scope IS NOT NULL
				AND RTS.Invoice IS NOT NULL

GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderTotalsByLineType] TO [Viewpoint]
GO
