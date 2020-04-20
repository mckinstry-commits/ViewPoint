SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvEquipSTDMtnGrpItemWOCnt] as
    
    Select EMCo,a.EMGroup,Equipment,StdMaintGroup,StdMaintItem,WOCount=Count(WorkOrder) From EMWI a
    Inner Join EMWS b on a.EMGroup = b.EMGroup and a.StatusCode = b.StatusCode
    Where StatusType <> 'F' and a.StdMaintGroup is Not Null and StdMaintItem is not null
    Group By EMCo,a.EMGroup,Equipment,StdMaintGroup,StdMaintItem

GO
GRANT SELECT ON  [dbo].[brvEquipSTDMtnGrpItemWOCnt] TO [public]
GRANT INSERT ON  [dbo].[brvEquipSTDMtnGrpItemWOCnt] TO [public]
GRANT DELETE ON  [dbo].[brvEquipSTDMtnGrpItemWOCnt] TO [public]
GRANT UPDATE ON  [dbo].[brvEquipSTDMtnGrpItemWOCnt] TO [public]
GO
