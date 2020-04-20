
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMWorkCompletedAll]
AS
SELECT vSMWorkCompleted.SMWorkCompletedID AS KeyID, vSMWorkCompleted.[Type], vSMWorkCompleted.IsDeleted, vSMWorkCompleted.UniqueAttchID,
	vSMWorkCompleted.APCo, vSMWorkCompleted.APInUseMth, vSMWorkCompleted.APInUseBatchId, vSMWorkCompleted.APTLKeyID, 
	vSMWorkCompleted.JCCo, vSMWorkCompleted.JCMth, vSMWorkCompleted.JCCostTrans, vSMWorkCompleted.JCCostTaxTrans,
	vSMWorkCompleted.InitialCostsCaptured, vSMWorkCompleted.CostsCaptured, vSMWorkCompleted.CostCo, vSMWorkCompleted.CostMth, vSMWorkCompleted.CostTrans,
	vSMWorkCompleted.PRGroup, vSMWorkCompleted.PREndDate, vSMWorkCompleted.PREmployee, vSMWorkCompleted.PRPaySeq, vSMWorkCompleted.PRPostSeq, vSMWorkCompleted.PRPostDate,
	vSMWorkCompleted.Provisional, vSMWorkCompleted.AutoAdded, vSMWorkCompleted.ReferenceNo, vSMWorkCompleted.CostDetailID,vSMWorkCompleted.NonBillable,
	vSMInvoice.Invoice, vSMInvoiceSession.SMSessionID, vSMInvoiceSession.SessionInvoice,
	CASE 
		WHEN vSMWorkCompleted.Provisional = 1 THEN 'Provisional'
		WHEN SMWorkOrderScope.PriceMethod = 'N' AND SMWorkOrderScope.[Service] IS NOT NULL THEN 'Periodic'
		WHEN SMWorkOrderScope.PriceMethod = 'F' THEN 'Flat Price'
		WHEN vSMWorkCompleted.NonBillable = 'Y' THEN 'Non-Billable'
		WHEN vSMSession.Prebilling = 1 THEN 'PreBilling'
		WHEN vSMInvoice.Invoiced = 1 THEN 'Billed'
		WHEN vSMInvoice.SMInvoiceID IS NOT NULL THEN 'Pending Inv'
		ELSE 'New'
	END [Status],
	SMWorkCompletedDetail.*,
	NULL AS CostTotal,
	COALESCE(CASE EMRC.Basis WHEN 'H' THEN SMWorkCompletedEquipment.TimeUnits WHEN 'U' THEN SMWorkCompletedEquipment.WorkUnits END, SMWorkCompletedPart.Quantity, SMWorkCompletedPurchase.Quantity) AS Quantity,
	COALESCE(SMWorkCompletedLabor.CostQuantity, SMWorkCompletedMisc.CostQuantity) AS CostQuantity,
	COALESCE(SMWorkCompletedEquipment.CostRate, SMWorkCompletedLabor.CostRate, SMWorkCompletedMisc.CostRate, SMWorkCompletedPart.CostRate, SMWorkCompletedPurchase.CostRate) AS CostRate,
	CASE WHEN vSMWorkCompleted.Type=2 THEN SMWorkCompletedLabor.ProjCost
		WHEN vSMWorkCompleted.Type=5 THEN SMWorkCompletedPurchase.ProjCost
		ELSE NULL END
	AS ProjCost,
	SMWorkCompletedPurchase.ActualUnits,
	COALESCE(SMWorkCompletedEquipment.ActualCost, SMWorkCompletedLabor.ActualCost, SMWorkCompletedMisc.ActualCost, SMWorkCompletedPart.ActualCost, SMWorkCompletedPurchase.ActualCost) AS ActualCost,
	COALESCE(SMWorkCompletedLabor.PriceQuantity, SMWorkCompletedMisc.PriceQuantity) AS PriceQuantity,
	COALESCE(SMWorkCompletedEquipment.MonthToPostCost, SMWorkCompletedPart.MonthToPostCost, SMWorkCompletedMisc.MonthToPostCost) AS MonthToPostCost,
	COALESCE(EMEM.[Description], SMWorkCompletedLabor.[Description], SMWorkCompletedMisc.[Description], POIT.[Description], HQMT.[Description], SMWorkCompletedPurchase.[Description]) AS [Description],
	SMWorkCompletedEquipment.EMCo, SMWorkCompletedEquipment.Equipment, SMWorkCompletedEquipment.EMGroup, SMWorkCompletedEquipment.RevCode, SMWorkCompletedEquipment.TimeUnits, SMWorkCompletedEquipment.WorkUnits,
	SMWorkCompletedLabor.PayType, vSMWorkCompleted.CostCo PRCo, SMWorkCompletedLabor.LaborCode, SMWorkCompletedLabor.Scope LaborScope, 
	SMWorkCompletedLabor.Class, SMWorkCompletedLabor.Craft, SMWorkCompletedLabor.Shift, SMWorkCompletedMisc.StandardItem,
	COALESCE(SMWorkCompletedPart.MatlGroup, POIT.MatlGroup, SMWorkCompletedPurchase.MatlGroup) MatlGroup,
	COALESCE(SMWorkCompletedPart.Part, POIT.Material, SMWorkCompletedPurchase.Part) Part,
	COALESCE(SMWorkCompletedPart.UM, SMWorkCompletedPurchase.UM) UM,
	COALESCE(SMWorkCompletedPart.PriceUM, SMWorkCompletedPurchase.PriceUM) PriceUM,
	COALESCE(SMWorkCompletedPart.CostECM, SMWorkCompletedPurchase.CostECM) CostECM, 
	COALESCE(SMWorkCompletedPart.PriceECM, SMWorkCompletedPurchase.PriceECM) PriceECM,
	SMWorkCompletedPart.[Source], SMWorkCompletedPart.INCo, SMWorkCompletedPart.INLocation, SMWorkCompletedPurchase.POCo, SMWorkCompletedPurchase.PO, SMWorkCompletedPurchase.PO PONumber, SMWorkCompletedPurchase.POItem, SMWorkCompletedPurchase.POItemLine,
	 vSMInvoice.BatchMonth InvoiceBatchMonth
FROM dbo.vSMWorkCompleted
	INNER JOIN dbo.SMWorkCompletedDetail ON --It is important to use the view here instead of the table so that when child views get refreshed for ud fields it will refresh this view
		vSMWorkCompleted.SMWorkCompletedID = SMWorkCompletedDetail.SMWorkCompletedID
	INNER JOIN dbo.SMWorkOrderScope ON
		SMWorkCompletedDetail.SMCo = SMWorkOrderScope.SMCo AND SMWorkCompletedDetail.WorkOrder = SMWorkOrderScope.WorkOrder AND SMWorkCompletedDetail.Scope = SMWorkOrderScope.Scope
	LEFT JOIN dbo.SMWorkCompletedEquipment ON 
		SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedEquipment.SMWorkCompletedID
		AND SMWorkCompletedDetail.IsSession = SMWorkCompletedEquipment.IsSession
		LEFT JOIN dbo.EMEM ON SMWorkCompletedEquipment.EMCo = EMEM.EMCo
			AND SMWorkCompletedEquipment.Equipment  = EMEM.Equipment
		LEFT JOIN dbo.EMRC ON SMWorkCompletedEquipment.EMGroup = EMRC.EMGroup
			AND SMWorkCompletedEquipment.RevCode = EMRC.RevCode
	LEFT JOIN dbo.SMWorkCompletedLabor ON 
		SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedLabor.SMWorkCompletedID
		AND SMWorkCompletedDetail.IsSession = SMWorkCompletedLabor.IsSession
	LEFT JOIN dbo.SMWorkCompletedMisc ON 
		SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedMisc.SMWorkCompletedID
		AND SMWorkCompletedDetail.IsSession = SMWorkCompletedMisc.IsSession
	LEFT JOIN dbo.SMWorkCompletedPart ON 
		SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedPart.SMWorkCompletedID
		AND SMWorkCompletedDetail.IsSession = SMWorkCompletedPart.IsSession
		LEFT JOIN dbo.HQMT ON SMWorkCompletedPart.MatlGroup = HQMT.MatlGroup
			AND SMWorkCompletedPart.Part = HQMT.Material 
	LEFT JOIN dbo.SMWorkCompletedPurchase ON 
		SMWorkCompletedDetail.SMWorkCompletedID = SMWorkCompletedPurchase.SMWorkCompletedID
		AND SMWorkCompletedDetail.IsSession = SMWorkCompletedPurchase.IsSession
		LEFT JOIN dbo.POIT ON SMWorkCompletedPurchase.POCo = POIT.POCo AND SMWorkCompletedPurchase.PO = POIT.PO AND SMWorkCompletedPurchase.POItem = POIT.POItem
	LEFT JOIN dbo.SMInvoiceDetail ON SMWorkCompletedDetail.SMCo = SMInvoiceDetail.SMCo AND
		SMWorkCompletedDetail.WorkOrder = SMInvoiceDetail.WorkOrder AND
		SMWorkCompletedDetail.WorkCompleted = SMInvoiceDetail.WorkCompleted
	LEFT JOIN dbo.vSMInvoice ON SMInvoiceDetail.SMCo = vSMInvoice.SMCo AND
		SMInvoiceDetail.Invoice = vSMInvoice.Invoice
	LEFT JOIN dbo.vSMInvoiceSession ON vSMInvoice.SMInvoiceID = vSMInvoiceSession.SMInvoiceID
	LEFT JOIN dbo.vSMSession WITH (NOLOCK) ON vSMInvoiceSession.SMSessionID = vSMSession.SMSessionID
WHERE
	--If we don't have the 3 sets of records that make up a work completed record then we don't want to include it in the results
	CASE vSMWorkCompleted.[Type] 
			WHEN 1 THEN SMWorkCompletedEquipment.SMWorkCompletedID
			WHEN 2 THEN SMWorkCompletedLabor.SMWorkCompletedID
			WHEN 3 THEN SMWorkCompletedMisc.SMWorkCompletedID
			WHEN 4 THEN SMWorkCompletedPart.SMWorkCompletedID
			WHEN 5 THEN SMWorkCompletedPurchase.SMWorkCompletedID
		END IS NOT NULL
GO

GRANT SELECT ON  [dbo].[SMWorkCompletedAll] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedAll] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedAll] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedAll] TO [public]
GO
