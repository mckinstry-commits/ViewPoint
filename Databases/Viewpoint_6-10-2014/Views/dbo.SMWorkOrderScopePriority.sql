SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 6/11/2013
-- Description:	Work Order Scope Priority as Integer
--	NOTE: This view is used for the enum SM_Dispatch.DataModels.SMWorkOrderScopePriority. Any changes
--	made to this view should be reflected in that enum.
-- =============================================
create VIEW [dbo].[SMWorkOrderScopePriority]
AS 
SELECT 
	SMWorkOrderScopeID,
	SMCo,
	WorkOrder,
	Scope,
	case
		when PriorityName = 'Low' then 1
		when PriorityName = 'Med' then 2
		when PriorityName = 'High' then 3
	end as Priority
FROM dbo.SMWorkOrderScope
GO
GRANT SELECT ON  [dbo].[SMWorkOrderScopePriority] TO [public]
GRANT INSERT ON  [dbo].[SMWorkOrderScopePriority] TO [public]
GRANT DELETE ON  [dbo].[SMWorkOrderScopePriority] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkOrderScopePriority] TO [public]
GRANT SELECT ON  [dbo].[SMWorkOrderScopePriority] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWorkOrderScopePriority] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWorkOrderScopePriority] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWorkOrderScopePriority] TO [Viewpoint]
GO
