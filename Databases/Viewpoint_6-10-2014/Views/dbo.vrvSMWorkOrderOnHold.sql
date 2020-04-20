SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  view [dbo].[vrvSMWorkOrderOnHold]
as

/***********************************************************************    
Author: 
Aaron Lang
   
Create date: 
6-21-2013
    
Usage:
This view contains all of the SMWorkOrderIDs and wheter or not they have any 
scopes on hold   

***********************************************************************/    
  
SELECT wo.SMWorkOrderID, Coalesce(woHold.OnHold,'N') as OnHold FROM SMWorkOrder wo
LEFT OUTER JOIN (SELECT scope.SMCo, scope.WorkOrder, scope.OnHold FROM SMWorkOrderScope scope 
		   WHERE scope.OnHold = 'Y' Group By scope.SMCo, scope.WorkOrder, scope.OnHold) woHold 
ON woHold.SMCo = wo.SMCo AND woHold.WorkOrder = wo.WorkOrder

GO
GRANT SELECT ON  [dbo].[vrvSMWorkOrderOnHold] TO [public]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderOnHold] TO [public]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderOnHold] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderOnHold] TO [public]
GRANT SELECT ON  [dbo].[vrvSMWorkOrderOnHold] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMWorkOrderOnHold] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMWorkOrderOnHold] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMWorkOrderOnHold] TO [Viewpoint]
GO
