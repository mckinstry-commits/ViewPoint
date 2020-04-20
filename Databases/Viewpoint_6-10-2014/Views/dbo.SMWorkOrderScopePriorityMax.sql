SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 6/11/2013
-- Description:	Max Work Order Scope Priority
--
-- Only shows Priority when there is One scope.
-- 
-- =============================================
create VIEW [dbo].[SMWorkOrderScopePriorityMax]
AS 

select
	sub.SMCo,
	sub.WorkOrder,
	case 
		when ScopeCount = 1 
		then sub.MaxPriority 
		else 0 
	end as MaxPriority 
from 
	(select 
		WorkOrder,
		SMCo,
		max(Priority) as MaxPriority,
		Sum(1) as ScopeCount
	from dbo.SMWorkOrderScopePriority
		group by WorkOrder, SMCo) sub
	
GO
GRANT SELECT ON  [dbo].[SMWorkOrderScopePriorityMax] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderScopePriorityMax] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderScopePriorityMax] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderScopePriorityMax] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderScopePriorityMax] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderScopePriorityMax] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderScopePriorityMax] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderScopePriorityMax] TO [Viewpoint]
GO
