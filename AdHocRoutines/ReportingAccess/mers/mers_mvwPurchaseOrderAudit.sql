USE Viewpoint
go

DROP VIEW mers.mvwPurchaseOrderAudit
go

CREATE VIEW mers.mvwPurchaseOrderAudit
as
SELECT 
	pohd.POCo
,	pohd.PO
,	pohd.udMCKPONumber
,	pohd.VendorGroup
,	pohd.Vendor
,	apvm.Name AS VendorName
,	CASE pohd.Status
		WHEN 0 THEN '0-Open'
		WHEN 1 THEN '1-Complete'
		WHEN 2 THEN '2-Closed'
		ELSE CAST(pohd.Status AS VARCHAR(5)) + '-Unknown'
	END AS POStatus
,	poit.POItem
,	CASE poit.ItemType
		WHEN 1 THEN '1-Job'
        WHEN 2 THEN '2-Inventory'
        WHEN 3 THEN '3-Expense'
        WHEN 4 THEN '4-Equipment'
        WHEN 5 THEN '5-EM Work Order'
        WHEN 6 THEN '6-SM Work Order'
        ELSE CAST(poit.ItemType AS VARCHAR(5)) + '-Unknown'
	END AS POItemType
,	poit.SMCo
,	smss.Description AS SMServiceSite
,	poit.SMWorkOrder
,	poit.SMScope
,	CASE
		WHEN smss.Job IS NULL THEN 'BreakFix'
		ELSE 'PMContract'
	END AS WorkOrderType
,	smss.JCCo 
,	jcci.Contract
,	jccm.Description AS ContractDesc
,	jcci.Item AS ContractItem
,	smss.Job 
,	jcjm.udCGCJob AS CGCJob
,	jcjm.Description AS JobDesc
,	poit.SMPhaseGroup AS PhaseGroup
,	poit.SMPhase AS Phase
,	poit.SMJCCostType AS CostType
,	poit.GLCo
,	poit.GLAcct
,	pohd.OrderDate
,	pohd.OrderedBy
,	poit.OrigCost
,	poit.CurCost
,	poit.BOCost
,	poit.RecvdCost
,	poit.RemCost
,	poit.TotalCost
,	poit.TaxGroup
,	poit.TaxCode
,	poit.TotalTax
--,	poit.JCCo
--,	poit.Job
--,	poit.PhaseGroup
--,	poit.Phase
--,	poit.JCCType
--,	jcch.JCCo
--,	jcch.Job
--,	jcch.CostType
FROM 
	POHD pohd
LEFT OUTER JOIN POIT poit ON 
	pohd.POCo=poit.POCo
AND pohd.PO=poit.PO
LEFT OUTER JOIN APVM apvm ON
	pohd.VendorGroup=apvm.VendorGroup
AND pohd.Vendor=apvm.Vendor
LEFT OUTER JOIN SMWorkCompleted smwo_wc ON
	poit.SMCo=smwo_wc.SMCo
AND poit.SMWorkOrder=smwo_wc.WorkOrder
AND poit.SMScope=smwo_wc.Scope
AND poit.POItem=smwo_wc.POItem
AND poit.POCo=smwo_wc.POCo
AND poit.PO=smwo_wc.PO
LEFT OUTER JOIN dbo.SMWorkOrderScope smwo_scope ON
	smwo_wc.SMCo=smwo_scope.SMCo
AND smwo_wc.WorkOrder=smwo_scope.WorkOrder
AND smwo_wc.Scope=smwo_scope.Scope
LEFT OUTER JOIN SMWorkOrder smwo ON
	smwo.SMCo=smwo_wc.SMCo
AND smwo.WorkOrder=smwo_wc.WorkOrder
LEFT OUTER JOIN dbo.SMServiceSite smss ON
	smwo.SMCo=smss.SMCo
AND smwo.ServiceSite=smss.ServiceSite
LEFT OUTER JOIN JCCH jcch ON
	jcch.JCCo=smss.JCCo
AND jcch.Job=smss.Job
AND jcch.PhaseGroup=smwo_wc.PhaseGroup
AND jcch.Phase=smwo_scope.Phase
AND jcch.CostType=smwo_wc.JCCostType 
LEFT OUTER JOIN JCJP jcjp ON
	jcch.JCCo=jcjp.JCCo
AND jcch.Job=jcjp.Job
AND jcch.PhaseGroup=jcjp.PhaseGroup
AND jcch.Phase=jcjp.Phase
LEFT OUTER JOIN JCJM jcjm ON
	jcjp.JCCo=jcjm.JCCo
AND jcjp.Job=jcjm.Job
LEFT OUTER JOIN JCCI jcci ON
	jcjp.JCCo=jcci.JCCo
AND jcjp.Contract=jcci.Contract
AND jcjp.Item=jcci.Item
LEFT OUTER JOIN JCCM jccm ON
	jcci.JCCo=jccm.JCCo
AND jcci.Contract=jccm.Contract
--WHERE 
--	smwo.SMCo=1
--and	poit.ItemType =6 --IS NOT null
--ORDER BY
--	pohd.POCo
--,	pohd.PO
GO

GRANT SELECT ON mers.mvwPurchaseOrderAudit TO PUBLIC
GO


SELECT * FROM mers.mvwPurchaseOrderAudit ORDER BY POCo,	PO