SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[viDim_EMWorkOrder] AS

/**************************************************
 * ALTERED:		TMS 2009-06-03
 * Modified:	HH 2010-11-04	#135047	Join bEMCO for company security
 * Usage:  Dimension View for EM Work Orders 
 *		   for use in SSAS Cubes. 
 *
 **************************************************/

SELECT 
	WorkOrder.KeyID		AS WorkOrderID
,	bEMCO.KeyID AS EMCoID
,	WorkOrder.WorkOrder
,	WorkOrder.Description AS WorkOrderDescription
,	WorkOrder.WorkOrder + '  ' + WorkOrder.Description AS WorkOrderAndDescription
,	WorkOrder.Complete
,	WorkOrderItems.KeyID as WorkOrderItemID
,	Cast(WorkOrderItems.WOItem as varchar) + '  ' + WorkOrderItems.Description as WorkOrderItemAndDescription
,	Case when WorkOrderItems.StdMaintGroup is not null then 'Standard Maintenance'
		 else 'Non Standard Maintenance'
	End as StdMaint_Or_NonStdMaint
,	Case when WorkOrderItems.Priority='N' then 'Normal'
		 when WorkOrderItems.Priority='U' then 'Urgent'
		 when WorkOrderItems.Priority='L' then 'Low'
	End as Priority

FROM 
	bEMWH WorkOrder With (NoLock)
		JOIN
	bEMWI WorkOrderItems With (NoLock)
		ON	WorkOrderItems.EMCo=WorkOrder.EMCo
		AND WorkOrderItems.WorkOrder=WorkOrder.WorkOrder
Inner Join bEMCO With (NoLock) on bEMCO.EMCo = WorkOrder.EMCo
Inner Join vDDBICompanies With (NoLock) ON vDDBICompanies.Co=WorkOrder.EMCo
		

UNION ALL 

-- Unassigned record
SELECT 
	 0		,null	,null	,'Unassigned'	,null, null, null
	,null
	,null
	,null


GO
GRANT SELECT ON  [dbo].[viDim_EMWorkOrder] TO [public]
GRANT INSERT ON  [dbo].[viDim_EMWorkOrder] TO [public]
GRANT DELETE ON  [dbo].[viDim_EMWorkOrder] TO [public]
GRANT UPDATE ON  [dbo].[viDim_EMWorkOrder] TO [public]
GO
