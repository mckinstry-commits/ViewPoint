SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPRMechWO]
AS

-- PR Employees by Work Order for Mechanics Time
-- Shows one line per work order/Mechanic (Using Mechanic from Line level)  
-- Filter in PT for mechanic and EM Co

select h.WorkOrder, h.Description, h.Equipment, h.Shop, h.EMCo ,i.Mechanic

from bEMWH h with (nolock) 
	join bEMWI i with (nolock)on i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder
	join bEMWS s with (nolock)on  s.EMGroup = i.EMGroup and s.StatusCode = i.StatusCode

where  s.StatusType <> 'F'and i.Mechanic is not null	

group by h.EMCo ,h.WorkOrder,h.Equipment, h.Shop, h.Description, i.Mechanic

GO
GRANT SELECT ON  [dbo].[ptvPRMechWO] TO [public]
GRANT INSERT ON  [dbo].[ptvPRMechWO] TO [public]
GRANT DELETE ON  [dbo].[ptvPRMechWO] TO [public]
GRANT UPDATE ON  [dbo].[ptvPRMechWO] TO [public]
GO
