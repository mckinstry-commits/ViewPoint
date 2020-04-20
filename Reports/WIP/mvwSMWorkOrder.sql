IF OBJECT_ID ('dbo.mvwSMWorkOrder', 'view') IS NOT NULL
DROP VIEW dbo.mvwSMWorkOrder;
GO

/******************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- -----------------------------------------------
** 10/29/2014 Amit Mody			Authored
** 
******************************************************************************/

CREATE VIEW dbo.mvwSMWorkOrder
AS
SELECT
	dbo.SMWorkCompletedDetail.SMCo, 
	dbo.SMWorkCompletedDetail.WorkOrder, 
	dbo.SMWorkCompletedDetail.WorkCompleted, 
	dbo.SMWorkCompletedDetail.SMWorkCompletedID, 
	dbo.SMWorkCompletedDetail.SMWorkCompletedDetailID, 
	--dbo.vSMWorkCompleted.SMWorkCompletedID AS KeyID, 
	dbo.vSMWorkCompleted.Type, 
	dbo.vSMWorkCompleted.IsDeleted, 
	--dbo.vSMWorkCompleted.UniqueAttchID, 
	dbo.vSMWorkCompleted.APCo, 
	--dbo.vSMWorkCompleted.APInUseMth, 
	--dbo.vSMWorkCompleted.APInUseBatchId, 
	--dbo.vSMWorkCompleted.APTLKeyID, 
	--dbo.vSMWorkCompleted.JCCo, 
	--dbo.vSMWorkCompleted.JCMth, 
	--dbo.vSMWorkCompleted.JCCostTrans, 
	--dbo.vSMWorkCompleted.JCCostTaxTrans, 
	dbo.vSMWorkCompleted.InitialCostsCaptured, 
	dbo.vSMWorkCompleted.CostsCaptured, 
	dbo.vSMWorkCompleted.CostCo, 
	--dbo.vSMWorkCompleted.CostMth, 
	--dbo.vSMWorkCompleted.CostTrans, 
	--dbo.vSMWorkCompleted.PRGroup, 
	--dbo.vSMWorkCompleted.PREndDate, 
	--dbo.vSMWorkCompleted.PREmployee, 
	--dbo.vSMWorkCompleted.PRPaySeq, 
	--dbo.vSMWorkCompleted.PRPostSeq, 
	--dbo.vSMWorkCompleted.PRPostDate, 
	--dbo.vSMWorkCompleted.Provisional, 
	--dbo.vSMWorkCompleted.AutoAdded, 
	--dbo.vSMWorkCompleted.ReferenceNo, 
	--dbo.vSMWorkCompleted.CostDetailID, 
	dbo.vSMWorkCompleted.NonBillable, 
	----dbo.vSMInvoice.Invoice, 
	----dbo.vSMInvoiceSession.SMSessionID, 
	----dbo.vSMInvoiceSession.SessionInvoice, 
	----CASE WHEN vSMWorkCompleted.Provisional = 1 THEN 'Provisional' WHEN SMWorkOrderScope.PriceMethod = 'N' AND SMWorkOrderScope.[Service] IS NOT NULL 
	----THEN 'Periodic' WHEN SMWorkOrderScope.PriceMethod = 'F' THEN 'Flat Price' WHEN vSMWorkCompleted.NonBillable = 'Y' THEN 'Non-Billable' WHEN vSMSession.Prebilling = 1 THEN 'PreBilling' WHEN vSMInvoice.Invoiced
	---- = 1 THEN 'Billed' WHEN vSMInvoice.SMInvoiceID IS NOT NULL THEN 'Pending Inv' ELSE 'New' END AS Status, 
	--dbo.SMWorkCompletedDetail.IsSession, 
	--dbo.SMWorkCompletedDetail.Scope, 
	--dbo.SMWorkCompletedDetail.Date, 
	--dbo.SMWorkCompletedDetail.Agreement, 
	--dbo.SMWorkCompletedDetail.Revision, 
	--dbo.SMWorkCompletedDetail.Coverage, 
	--dbo.SMWorkCompletedDetail.Technician, 
	--dbo.SMWorkCompletedDetail.ServiceSite, 
	--dbo.SMWorkCompletedDetail.ServiceItem, 
	dbo.SMWorkCompletedDetail.SMCostType,
	dbo.SMCostType.Description AS SMCostTypeDescription,
	dbo.SMWorkCompletedDetail.PhaseGroup, 
	dbo.SMWorkCompletedDetail.JCCostType, 
	dbo.SMWorkCompletedDetail.PriceRate, 
	dbo.SMWorkCompletedDetail.PriceTotal, 
	--dbo.SMWorkCompletedDetail.TaxType, 
	--dbo.SMWorkCompletedDetail.TaxGroup, 
	--dbo.SMWorkCompletedDetail.TaxCode, 
	--dbo.SMWorkCompletedDetail.TaxBasis, 
	--dbo.SMWorkCompletedDetail.TaxAmount, 
	dbo.SMWorkCompletedDetail.NoCharge, 
	dbo.SMWorkCompletedDetail.GLCo, 
	dbo.SMWorkCompletedDetail.CostAccount, 
	dbo.SMWorkCompletedDetail.CostWIPAccount, 
	dbo.SMWorkCompletedDetail.RevenueAccount, 
	dbo.SMWorkCompletedDetail.RevenueWIPAccount, 
	--dbo.SMWorkCompletedDetail.DeprecatedSMInvoiceID,
	--dbo.SMWorkCompletedDetail.Notes, 
	--dbo.SMWorkCompletedDetail.UseAgreementRates, 
	--NULL AS CostTotal, 
	COALESCE (CASE EMRC.Basis WHEN 'H' THEN SMWorkCompletedEquipment.TimeUnits WHEN 'U' THEN SMWorkCompletedEquipment.WorkUnits END, 
	dbo.SMWorkCompletedPart.Quantity, 
	dbo.SMWorkCompletedPurchase.Quantity) AS Quantity, 
	COALESCE (dbo.SMWorkCompletedLabor.CostQuantity, 
	dbo.SMWorkCompletedMisc.CostQuantity) AS CostQuantity, 
	COALESCE (dbo.SMWorkCompletedEquipment.CostRate, 
	dbo.SMWorkCompletedLabor.CostRate, 
	dbo.SMWorkCompletedMisc.CostRate, 
	dbo.SMWorkCompletedPart.CostRate, 
	dbo.SMWorkCompletedPurchase.CostRate) AS CostRate, 
	CASE WHEN vSMWorkCompleted.Type = 2 THEN SMWorkCompletedLabor.ProjCost WHEN vSMWorkCompleted.Type = 5 THEN SMWorkCompletedPurchase.ProjCost ELSE NULL END AS ProjCost, 
	dbo.SMWorkCompletedPurchase.ActualUnits, 
	--COALESCE (dbo.SMWorkCompletedEquipment.ActualCost, 
	--dbo.SMWorkCompletedLabor.ActualCost, 
	--dbo.SMWorkCompletedMisc.ActualCost, 
	--dbo.SMWorkCompletedPart.ActualCost, 
	--dbo.SMWorkCompletedPurchase.ActualCost) AS ActualCost, 
	COALESCE (dbo.SMWorkCompletedEquipment.ActualCost, 0) +  
		COALESCE (dbo.SMWorkCompletedLabor.ActualCost, 0) + 
		COALESCE (dbo.SMWorkCompletedMisc.ActualCost, 0) + 
		COALESCE (dbo.SMWorkCompletedPart.ActualCost, 0) + 
		COALESCE (dbo.SMWorkCompletedPurchase.ActualCost, 0) AS ActualCost,
	COALESCE (dbo.SMWorkCompletedLabor.PriceQuantity, 
	dbo.SMWorkCompletedMisc.PriceQuantity) AS PriceQuantity, 
	COALESCE (dbo.SMWorkCompletedEquipment.MonthToPostCost, dbo.SMWorkCompletedPart.MonthToPostCost, dbo.SMWorkCompletedMisc.MonthToPostCost) AS MonthToPostCost--, 
	--COALESCE (dbo.EMEM.Description, 
	--dbo.SMWorkCompletedLabor.Description, 
	--dbo.SMWorkCompletedMisc.Description, 
	----dbo.POIT.Description, 
	--dbo.HQMT.Description, 
	--dbo.SMWorkCompletedPurchase.Description) AS Description, 
	--dbo.SMWorkCompletedEquipment.EMCo, 
	--dbo.SMWorkCompletedEquipment.Equipment, 
	--dbo.SMWorkCompletedEquipment.EMGroup, 
	--dbo.SMWorkCompletedEquipment.RevCode, 
	--dbo.SMWorkCompletedEquipment.TimeUnits, 
	--dbo.SMWorkCompletedEquipment.WorkUnits, 
	--dbo.SMWorkCompletedLabor.PayType, 
	--dbo.vSMWorkCompleted.CostCo AS PRCo, 
	--dbo.SMWorkCompletedLabor.LaborCode, 
	--dbo.SMWorkCompletedLabor.Scope AS LaborScope, 
	--dbo.SMWorkCompletedLabor.Class, 
	--dbo.SMWorkCompletedLabor.Craft, 
	--dbo.SMWorkCompletedLabor.Shift, 
	--dbo.SMWorkCompletedMisc.StandardItem, 
	----COALESCE (dbo.SMWorkCompletedPart.MatlGroup, dbo.POIT.MatlGroup, dbo.SMWorkCompletedPurchase.MatlGroup) AS MatlGroup, 
	----COALESCE (dbo.SMWorkCompletedPart.Part, dbo.POIT.Material, dbo.SMWorkCompletedPurchase.Part) AS Part, 
	--COALESCE (dbo.SMWorkCompletedPart.UM, dbo.SMWorkCompletedPurchase.UM) AS UM, 
	--COALESCE (dbo.SMWorkCompletedPart.PriceUM, 
	--dbo.SMWorkCompletedPurchase.PriceUM) AS PriceUM, 
	--COALESCE (dbo.SMWorkCompletedPart.CostECM, 
	--dbo.SMWorkCompletedPurchase.CostECM) 
	--AS CostECM, COALESCE (dbo.SMWorkCompletedPart.PriceECM, 
	--dbo.SMWorkCompletedPurchase.PriceECM) AS PriceECM, 
	--dbo.SMWorkCompletedPart.Source, 
	--dbo.SMWorkCompletedPart.INCo, 
	--dbo.SMWorkCompletedPart.INLocation, 
	--dbo.SMWorkCompletedPurchase.POCo, 
	--dbo.SMWorkCompletedPurchase.PO, 
	--dbo.SMWorkCompletedPurchase.PO AS PONumber, 
	--dbo.SMWorkCompletedPurchase.POItem, 
	--dbo.SMWorkCompletedPurchase.POItemLine
	----,dbo.vSMInvoice.BatchMonth AS InvoiceBatchMonth
FROM            
	dbo.vSMWorkCompleted INNER JOIN
	dbo.SMWorkCompletedDetail ON dbo.vSMWorkCompleted.SMWorkCompletedID = dbo.SMWorkCompletedDetail.SMWorkCompletedID INNER JOIN
	dbo.SMWorkOrderScope ON dbo.SMWorkCompletedDetail.SMCo = dbo.SMWorkOrderScope.SMCo AND dbo.SMWorkCompletedDetail.WorkOrder = dbo.SMWorkOrderScope.WorkOrder AND 
		dbo.SMWorkCompletedDetail.Scope = dbo.SMWorkOrderScope.Scope LEFT OUTER JOIN
	dbo.SMWorkCompletedEquipment ON dbo.SMWorkCompletedDetail.SMWorkCompletedID = dbo.SMWorkCompletedEquipment.SMWorkCompletedID AND 
		dbo.SMWorkCompletedDetail.IsSession = dbo.SMWorkCompletedEquipment.IsSession LEFT OUTER JOIN
	dbo.EMEM ON dbo.SMWorkCompletedEquipment.EMCo = dbo.EMEM.EMCo AND dbo.SMWorkCompletedEquipment.Equipment = dbo.EMEM.Equipment LEFT OUTER JOIN
	dbo.EMRC ON dbo.SMWorkCompletedEquipment.EMGroup = dbo.EMRC.EMGroup AND dbo.SMWorkCompletedEquipment.RevCode = dbo.EMRC.RevCode LEFT OUTER JOIN
	dbo.SMWorkCompletedLabor ON dbo.SMWorkCompletedDetail.SMWorkCompletedID = dbo.SMWorkCompletedLabor.SMWorkCompletedID AND 
		dbo.SMWorkCompletedDetail.IsSession = dbo.SMWorkCompletedLabor.IsSession LEFT OUTER JOIN
	dbo.SMWorkCompletedMisc ON dbo.SMWorkCompletedDetail.SMWorkCompletedID = dbo.SMWorkCompletedMisc.SMWorkCompletedID AND 
		dbo.SMWorkCompletedDetail.IsSession = dbo.SMWorkCompletedMisc.IsSession LEFT OUTER JOIN
	dbo.SMWorkCompletedPart ON dbo.SMWorkCompletedDetail.SMWorkCompletedID = dbo.SMWorkCompletedPart.SMWorkCompletedID AND 
		dbo.SMWorkCompletedDetail.IsSession = dbo.SMWorkCompletedPart.IsSession LEFT OUTER JOIN
	dbo.HQMT ON dbo.SMWorkCompletedPart.MatlGroup = dbo.HQMT.MatlGroup AND dbo.SMWorkCompletedPart.Part = dbo.HQMT.Material LEFT OUTER JOIN
	dbo.SMWorkCompletedPurchase ON dbo.SMWorkCompletedDetail.SMWorkCompletedID = dbo.SMWorkCompletedPurchase.SMWorkCompletedID AND 
		dbo.SMWorkCompletedDetail.IsSession = dbo.SMWorkCompletedPurchase.IsSession LEFT OUTER JOIN
	dbo.SMCostType ON dbo.SMWorkCompletedDetail.SMCo=dbo.SMCostType.SMCo AND
		dbo.SMWorkCompletedDetail.SMCostType=dbo.SMCostType.SMCostType
	--LEFT OUTER JOIN
	--dbo.POIT ON dbo.SMWorkCompletedPurchase.POCo = dbo.POIT.POCo AND dbo.SMWorkCompletedPurchase.PO = dbo.POIT.PO AND dbo.SMWorkCompletedPurchase.POItem = dbo.POIT.POItem LEFT OUTER JOIN
	--dbo.SMInvoiceDetail ON dbo.SMWorkCompletedDetail.SMCo = dbo.SMInvoiceDetail.SMCo AND dbo.SMWorkCompletedDetail.WorkOrder = dbo.SMInvoiceDetail.WorkOrder AND 
	--	dbo.SMWorkCompletedDetail.WorkCompleted = dbo.SMInvoiceDetail.WorkCompleted LEFT OUTER JOIN
	--dbo.vSMInvoice ON dbo.SMInvoiceDetail.SMCo = dbo.vSMInvoice.SMCo AND dbo.SMInvoiceDetail.Invoice = dbo.vSMInvoice.Invoice LEFT OUTER JOIN
	--dbo.vSMInvoiceSession ON dbo.vSMInvoice.SMInvoiceID = dbo.vSMInvoiceSession.SMInvoiceID LEFT OUTER JOIN
	--dbo.vSMSession WITH (NOLOCK) ON dbo.vSMInvoiceSession.SMSessionID = dbo.vSMSession.SMSessionID
WHERE        
	(CASE vSMWorkCompleted.[Type] WHEN 1 THEN SMWorkCompletedEquipment.SMWorkCompletedID WHEN 2 THEN SMWorkCompletedLabor.SMWorkCompletedID WHEN 3 THEN SMWorkCompletedMisc.SMWorkCompletedID
	 WHEN 4 THEN SMWorkCompletedPart.SMWorkCompletedID WHEN 5 THEN SMWorkCompletedPurchase.SMWorkCompletedID END IS NOT NULL)
--ORDER BY
--	dbo.SMWorkCompletedDetail.SMCo, 
--	dbo.SMWorkCompletedDetail.WorkOrder
GO

GRANT SELECT ON dbo.mvwSMWorkOrder TO [public]
GO

-- Test Scripts
--select * from dbo.mvwSMWorkOrder