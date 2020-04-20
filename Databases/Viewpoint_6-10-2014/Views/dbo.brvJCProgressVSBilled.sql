SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE    view [dbo].[brvJCProgressVSBilled] as select 
       JCID.JCCo, HQCO.Name, JCID.Mth, JCID.Contract, ContractDescr = JCCM.Description, JCID.Item, ItemDescr= JCCI.Description,
       ItemUM = JCCI.UM, ItemSICode = JCCI.SICode, BillActualDate = JCID.ActualDate, JCID.ContractUnits, 
       UnitPrice = Case when JCID.TransSource = 'JC OrigEst' then JCID.UnitPrice else 0 end, JCID.ContractAmt, JCID.BilledUnits, JCID.BilledAmt, 
       ProgActualUnits=0.00, ProgActualCost=0.00, ProgActualDate = '01/01/1950',
       EstCost = 0, EstUnits = 0, ProjCost = 0, ProjUnits = 0
          
   from JCID With (NoLock)
      join JCCI  With (NoLock) on
   	JCID.JCCo = JCCI.JCCo and
   	JCID.Contract = JCCI.Contract and
   	JCID.Item = JCCI.Item
      join JCCM  With (NoLock) on
   	JCID.JCCo = JCCM.JCCo and
   	JCID.Contract = JCCM.Contract
      join HQCO With (NoLock) on
   		JCID.JCCo = HQCO.HQCo
   
       union all
       
       select JCCD.JCCo, HQCO.Name, JCCD.Mth, JCJP.Contract, JCCM.Description, JCJP.Item, ItemDescr= JCCI.Description,
      	JCCI.UM, JCCI.SICode, '01/01/1950',  0, 
           0, 0, 0, 0,
       	Case when JCCH.BillFlag = 'Y' then JCCD.ActualUnits else 0 end, JCCD.ActualCost, JCCD.ActualDate,
       	JCCD.EstCost, 	
       	Case when JCCH.BillFlag = 'Y' then JCCD.EstUnits else 0 end, JCCD.ProjCost, 
       	Case when JCCH.BillFlag = 'Y' then JCCD.ProjUnits else 0 end
       
       from JCCD With (NoLock)
       
       join JCJP With (NoLock) on 
   	JCCD.JCCo=JCJP.JCCo and 
   	JCCD.Job=JCJP.Job and
   	JCCD.Phase=JCJP.Phase and 
   	JCCD.PhaseGroup=JCJP.PhaseGroup
         join JCCI  With (NoLock) on
   		JCJP.JCCo = JCCI.JCCo and
   		JCJP.Contract = JCCI.Contract and
   		JCJP.Item = JCCI.Item
         join JCCM  With (NoLock) on
   		JCJP.JCCo = JCCM.JCCo and
   		JCJP.Contract = JCCM.Contract 
       join HQCO With (NoLock) on
   		JCCD.JCCo = HQCO.HQCo 
       join  JCCH With (NoLock) on
   	JCCD.JCCo=JCCH.JCCo and 
   	JCCD.Job=JCCH.Job and
   	JCCD.Phase=JCCH.Phase and 
   	JCCD.PhaseGroup=JCCH.PhaseGroup and
   	JCCD.CostType = JCCH.CostType  
   	
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCProgressVSBilled] TO [public]
GRANT INSERT ON  [dbo].[brvJCProgressVSBilled] TO [public]
GRANT DELETE ON  [dbo].[brvJCProgressVSBilled] TO [public]
GRANT UPDATE ON  [dbo].[brvJCProgressVSBilled] TO [public]
GRANT SELECT ON  [dbo].[brvJCProgressVSBilled] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCProgressVSBilled] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCProgressVSBilled] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCProgressVSBilled] TO [Viewpoint]
GO
