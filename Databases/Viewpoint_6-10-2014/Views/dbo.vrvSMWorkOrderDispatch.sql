SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvSMWorkOrderDispatch]
as

/***********************************************************************    
Author: 
Paul Wiegardt
   
Create date: 
5-10-2013

Update:
	6/24/2013 P. Wiegardt - Removed restriction on Job type to include Job type.
							Added vrvSMWorkOrderOnHold and SMWorkOrderScopePriorityMax
	11/12/2013 David S.		Fix for discrepency between hotfix and 6.7 branch
    
Usage:
This View contains all information the SM Dispatch Board needs to display
Work Orders.

***********************************************************************/    
  
select
	wo.SMCo,
	wo.WorkOrder,
	wo.SMWorkOrderID,
	wo.Customer,
	wo.Job,
	wo.ServiceSite,
	wo.Description as WorkOrderDescription,
	ss.Description as SiteDescription,
	stat.Status,
	workPri.MaxPriority as Priority,
	hold.OnHold
from dbo.SMWorkOrder wo
	INNER JOIN SMServiceSite ss
		ON wo.SMCo = ss.SMCo
		AND wo.ServiceSite = ss.ServiceSite	
	INNER JOIN SMWorkOrderStatus stat
		ON stat.SMCo = wo.SMCo
		AND stat.WorkOrder = wo.WorkOrder
	left join dbo.SMWorkOrderScopePriorityMax workPri on workPri.SMCo = wo.SMCo and workPri.WorkOrder = wo.WorkOrder
	inner Join vrvSMWorkOrderOnHold hold on wo.SMWorkOrderID = hold.SMWorkOrderID
-- where wo.Customer is not null -- No 'Job' type Work Orders
GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderDispatch] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderDispatch] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderDispatch] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderDispatch] TO [public]
GO
