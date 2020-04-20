SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMServiceableItemWOList]
AS

SELECT DISTINCT * FROM (
SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkCompleted.ServiceItem, SMWorkOrder.SMWorkOrderID
FROM dbo.SMWorkOrder
INNER JOIN 
	dbo.SMWorkCompleted ON 
	SMWorkCompleted.SMCo = SMWorkOrder.SMCo 
	AND SMWorkCompleted.WorkOrder = SMWorkOrder.WorkOrder
WHERE SMWorkCompleted.ServiceItem IS NOT NULL
GROUP BY SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkCompleted.ServiceItem, SMWorkOrder.SMWorkOrderID
UNION
SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkOrderScope.ServiceItem, SMWorkOrder.SMWorkOrderID
FROM dbo.SMWorkOrder
INNER JOIN
	dbo.SMWorkOrderScope ON
	SMWorkOrderScope.SMCo = SMWorkOrder.SMCo
	AND SMWorkOrderScope.WorkOrder = SMWorkOrder.WorkOrder
WHERE SMWorkOrderScope.ServiceItem IS NOT NULL
GROUP BY SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkOrderScope.ServiceItem, SMWorkOrder.SMWorkOrderID, SMWorkOrder.SMWorkOrderID
UNION
SELECT SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkOrderScopeTask.ServiceItem, SMWorkOrder.SMWorkOrderID
FROM dbo.SMWorkOrder
INNER JOIN
	dbo.SMWorkOrderScopeTask ON
	SMWorkOrderScopeTask.SMCo = SMWorkOrder.SMCo
	AND SMWorkOrderScopeTask.WorkOrder = SMWorkOrder.WorkOrder
WHERE SMWorkOrderScopeTask.ServiceItem IS NOT NULL
GROUP BY SMWorkOrder.SMCo, SMWorkOrder.WorkOrder, SMWorkOrder.[Description], SMWorkOrder.ServiceSite, SMWorkOrderScopeTask.ServiceItem, SMWorkOrder.SMWorkOrderID
) WOrkOrders

GO
GRANT SELECT ON  [dbo].[SMServiceableItemWOList] TO [public]
GRANT INSERT ON  [dbo].[SMServiceableItemWOList] TO [public]
GRANT DELETE ON  [dbo].[SMServiceableItemWOList] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceableItemWOList] TO [public]
GO
