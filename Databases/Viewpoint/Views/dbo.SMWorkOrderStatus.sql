SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.SMWorkOrderStatus
AS
SELECT     dbo.SMWorkOrder.SMCo, dbo.SMWorkOrder.WorkOrder, 
                      CASE WHEN SMWorkOrder.WOStatus = 1 THEN 'Closed' WHEN SMWorkOrder.WOStatus = 2 THEN 'Canceled' WHEN WT.TripCount IS NULL AND 
                      WC.WorkCompletedCount IS NULL THEN 'New' WHEN (WT.MinStatus IS NULL OR
                      WT.MinStatus = 1) AND (WS.MinStatus IS NULL OR
                      WS.MinStatus = 'Y') THEN 'Complete' ELSE 'Open' END AS Status
FROM         dbo.SMWorkOrder LEFT OUTER JOIN
                          (SELECT     SMCo, WorkOrder, MIN(Status) AS MinStatus, COUNT(Status) AS TripCount
                            FROM          dbo.SMTrip
                            GROUP BY SMCo, WorkOrder) AS WT ON dbo.SMWorkOrder.SMCo = WT.SMCo AND dbo.SMWorkOrder.WorkOrder = WT.WorkOrder LEFT OUTER JOIN
                          (SELECT     SMCo, WorkOrder, MIN(IsComplete) AS MinStatus
                            FROM          dbo.SMWorkOrderScope
                            GROUP BY SMCo, WorkOrder) AS WS ON WS.SMCo = dbo.SMWorkOrder.SMCo AND WS.WorkOrder = dbo.SMWorkOrder.WorkOrder LEFT OUTER JOIN
                          (SELECT     SMCo, WorkOrder, COUNT(WorkCompleted) AS WorkCompletedCount
                            FROM          dbo.SMWorkCompleted
                            WHERE AutoAdded = 0
                            GROUP BY SMCo, WorkOrder) AS WC ON WC.SMCo = dbo.SMWorkOrder.SMCo AND WC.WorkOrder = dbo.SMWorkOrder.WorkOrder

GO
GRANT SELECT ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderStatus] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderStatus] TO [public]
GO
