SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMWHStdMaintGroupNotes]
/*******************************
* Created: TRL 04/16/08 - Issue 127348 
* Modified:
*
*Links Std Maint Group Notes form WO Items to Work Order Header
*
******************************/
as
/*Equipment*/
select Distinct i.EMCo,i.WorkOrder,i.Equipment,EquipOrComp=i.Equipment,m.Type,i.StdMaintGroup,Notes=convert(varchar(max),s.Notes)
From dbo.EMWI i with(nolock)
Inner Join EMSH s with(nolock)on s.EMCo=i.EMCo and s.Equipment = i.Equipment and s.StdMaintGroup=i.StdMaintGroup
Inner Join EMEM m with(nolock)on m.EMCo=i.EMCo and m.Equipment = i.Equipment
Inner Join EMWH h with(nolock)on h.EMCo=i.EMCo and h.WorkOrder = i.WorkOrder and h.Equipment = i.Equipment
Where m.Type = 'E' 
union all
/*Components*/
select Distinct i.EMCo,i.WorkOrder,i.Equipment,EquipOrComp=i.Component,m.Type,i.StdMaintGroup,Notes=convert(varchar(Max),s.Notes)
From dbo.EMWI i with(nolock)
Inner Join EMSH s with(nolock)on s.EMCo=i.EMCo and s.Equipment = i.Component and s.StdMaintGroup=i.StdMaintGroup
Inner Join EMEM m with(nolock)on s.EMCo=i.EMCo and s.Equipment = i.Component
Inner Join EMWH h with(nolock)on h.EMCo=i.EMCo and h.WorkOrder = i.WorkOrder and h.Equipment = i.Equipment
Where m.Type = 'C'

GO
GRANT SELECT ON  [dbo].[EMWHStdMaintGroupNotes] TO [public]
GRANT INSERT ON  [dbo].[EMWHStdMaintGroupNotes] TO [public]
GRANT DELETE ON  [dbo].[EMWHStdMaintGroupNotes] TO [public]
GRANT UPDATE ON  [dbo].[EMWHStdMaintGroupNotes] TO [public]
GRANT SELECT ON  [dbo].[EMWHStdMaintGroupNotes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMWHStdMaintGroupNotes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMWHStdMaintGroupNotes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMWHStdMaintGroupNotes] TO [Viewpoint]
GO
