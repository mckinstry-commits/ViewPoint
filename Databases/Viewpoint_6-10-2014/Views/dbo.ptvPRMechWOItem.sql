SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPRMechWOItem]
AS

-- Work Order items assigend to a mechanic for Mechanics Time Posting
-- Shows 1 line per WO item.  
-- Filter in PT on Mechanic, Work Order, and EMCo

select i.WOItem, i.Description, h.Equipment, h.Shop, i.Mechanic, h.WorkOrder, h.EMCo

from bEMWH  h with (nolock)
	join bEMWI i with (nolock)on i.EMCo = h.EMCo and i.WorkOrder = h.WorkOrder
	join bEMWS s with (nolock)on  s.EMGroup = i.EMGroup and s.StatusCode = i.StatusCode

where  s.StatusType <> 'F' and i.Mechanic is not null		

group by h.EMCo ,h.WorkOrder,i.WOItem, h.Equipment, h.Shop, i.Description, i.Mechanic

GO
GRANT SELECT ON  [dbo].[ptvPRMechWOItem] TO [public]
GRANT INSERT ON  [dbo].[ptvPRMechWOItem] TO [public]
GRANT DELETE ON  [dbo].[ptvPRMechWOItem] TO [public]
GRANT UPDATE ON  [dbo].[ptvPRMechWOItem] TO [public]
GRANT SELECT ON  [dbo].[ptvPRMechWOItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvPRMechWOItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvPRMechWOItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvPRMechWOItem] TO [Viewpoint]
GO
