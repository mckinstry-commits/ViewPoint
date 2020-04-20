SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.SMWorkOrderStatus
AS

-- 5-15-2013 Formatted for readability. Paul Wiegardt.
-- 5-20-2013 Changed "Completed" to check Trip.Status = 7. Paul Wiegardt.
-- 11/12/2013 David S.		Fix for discrepency between hotfix and 6.7 branch
-- 12/18/13 EricV TFS-70048 Refactored to allow use of indexes to improve performance

	SELECT SMCo, WorkOrder, 'Closed' [Status]
	FROM dbo.vSMWorkOrder
	WHERE WOStatus = 1
	
	UNION ALL
	
	SELECT SMCo, WorkOrder, 'Canceled' [Status]
	FROM dbo.vSMWorkOrder
	WHERE WOStatus = 2

	UNION ALL

	SELECT SMCo, WorkOrder, 'New' [Status]
	FROM dbo.vSMWorkOrder
	WHERE WOStatus = 0 AND
		NOT 
		(
			EXISTS(SELECT 1 FROM dbo.vSMTrip WHERE vSMWorkOrder.SMCo = vSMTrip.SMCo AND vSMWorkOrder.WorkOrder = vSMTrip.WorkOrder) OR
			EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted WHERE vSMWorkOrder.SMCo = vSMWorkCompleted.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWorkCompleted.AutoAdded = 0)
		)

	UNION ALL

	SELECT SMCo, WorkOrder, 'Open' [Status]
	FROM dbo.vSMWorkOrder
	WHERE WOStatus = 0 AND
		(
			EXISTS(SELECT 1 FROM dbo.vSMTrip WHERE vSMWorkOrder.SMCo = vSMTrip.SMCo AND vSMWorkOrder.WorkOrder = vSMTrip.WorkOrder) OR
			EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted WHERE vSMWorkOrder.SMCo = vSMWorkCompleted.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWorkCompleted.AutoAdded = 0)
		) AND
		(
			EXISTS(SELECT 1 FROM dbo.vSMWorkOrderScope WHERE vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWorkOrderScope.IsComplete = 'N') OR
			EXISTS(SELECT 1 FROM dbo.vSMTrip WHERE vSMWorkOrder.SMCo = vSMTrip.SMCo AND vSMWorkOrder.WorkOrder = vSMTrip.WorkOrder AND vSMTrip.[Status] <> 7)
		)

	UNION ALL

	SELECT SMCo, WorkOrder, 'Complete' [Status]
	FROM dbo.vSMWorkOrder
	WHERE WOStatus = 0 AND
		(
			EXISTS(SELECT 1 FROM dbo.vSMTrip WHERE vSMWorkOrder.SMCo = vSMTrip.SMCo AND vSMWorkOrder.WorkOrder = vSMTrip.WorkOrder) OR
			EXISTS(SELECT 1 FROM dbo.vSMWorkCompleted WHERE vSMWorkOrder.SMCo = vSMWorkCompleted.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkCompleted.WorkOrder AND vSMWorkCompleted.AutoAdded = 0)
		) AND
		NOT
		(
			EXISTS(SELECT 1 FROM dbo.vSMWorkOrderScope WHERE vSMWorkOrder.SMCo = vSMWorkOrderScope.SMCo AND vSMWorkOrder.WorkOrder = vSMWorkOrderScope.WorkOrder AND vSMWorkOrderScope.IsComplete = 'N') OR
			EXISTS(SELECT 1 FROM dbo.vSMTrip WHERE vSMWorkOrder.SMCo = vSMTrip.SMCo AND vSMWorkOrder.WorkOrder = vSMTrip.WorkOrder AND vSMTrip.[Status] <> 7)
		)
GO
GRANT SELECT ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderStatus] TO [public]
GO
