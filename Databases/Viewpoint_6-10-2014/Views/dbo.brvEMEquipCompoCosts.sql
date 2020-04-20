SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[brvEMEquipCompoCosts]
    
    /**************
     Created 11/14/02  NF
     Usage:  Used by the EM Costs Equipment and Components report.  View pulls detail from table joined to self into view so either Component records or Equipment records will print based on the Sort Order for the report.      
    **************/
    
     as Select EMCD.EMCo, 
            a.HQCo,
            HQ_Name = a.Name,
            EMCD.Mth, 
            EMCD.EMTrans, 
            EMCD.EMGroup, 
            EMCD.Equipment,
            EQ_Description = b.Description,
            Component = IsNull(EMCD.Component,''),
            CompDesc = c.Description,
            EMCD.CostCode, 
            EMCD.EMCostType, 
            EMCD.ActualDate, 
            EMCD.Source, 
            EMCD.Units, 
            EMCD.Dollars , 
            RecType = 'E' 
     From EMCD
     	join HQCO  a on EMCD.EMCo = a.HQCo 
     	left outer join EMEM b on EMCD.EMCo = b.EMCo and EMCD.Equipment = b.Equipment
     	left outer join EMEM c on EMCD.EMCo = c.EMCo and EMCD.Component = c.Equipment
     
     union 
     
     select EMCD.EMCo, 
            a.HQCo,
            HQ_Name = a.Name,
            EMCD.Mth, 
            EMCD.EMTrans, 
            EMCD.EMGroup, 
            EMCD.Equipment,
            EQ_Description = c.Description,
            EMCD.Component, 
            CompDesc = b.Description,
            EMCD.CostCode, 
            EMCD.EMCostType, 
            EMCD.ActualDate, 
            EMCD.Source, 
            EMCD.Units, 
            EMCD.Dollars , 
            RecType = 'C'
     From EMCD 
     	join HQCO  a on EMCD.EMCo = a.HQCo 
     	left outer join EMEM b on EMCD.EMCo = b.EMCo and EMCD.Component = b.Equipment
     	left outer join EMEM c on EMCD.EMCo = c.EMCo and EMCD.Equipment = c.Equipment
     
     Where Component Is Not Null

GO
GRANT SELECT ON  [dbo].[brvEMEquipCompoCosts] TO [public]
GRANT INSERT ON  [dbo].[brvEMEquipCompoCosts] TO [public]
GRANT DELETE ON  [dbo].[brvEMEquipCompoCosts] TO [public]
GRANT UPDATE ON  [dbo].[brvEMEquipCompoCosts] TO [public]
GRANT SELECT ON  [dbo].[brvEMEquipCompoCosts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMEquipCompoCosts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMEquipCompoCosts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMEquipCompoCosts] TO [Viewpoint]
GO
