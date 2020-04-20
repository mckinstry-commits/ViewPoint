SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  View [dbo].[brvEMMthDeprCostRev] as
   
   Select Type='R',EMCo=EMAR.EMCo, EMGroup=EMAR.EMGroup,Equip=EMAR.Equipment, Mth=EMAR.Month, 
          RevCode=EMAR.RevCode,CostCode=null, CostType=0, RevAvailableHrs=EMAR.AvailableHrs,
          RevActualWorkUnits=EMAR.ActualWorkUnits,RevActTime=EMAR.Actual_Time,RevActAmt=EMAR.ActualAmt,
          CostActualUnits=0, CostActCost=0, Asset=null, AmtTaken=0
    FROM EMAR with (NOLOCK)
   
   Union all
   
   Select 'C',EMMC.EMCo, EMMC.EMGroup,EMMC.Equipment, EMMC.Month, 
          RevCode=null, EMMC.CostCode, EMMC.CostType, revAvailableHrs=0,
          RevActualWorkUnits=0, RevActTime=0, RevActAmt=0, 
          CostActualUnits=EMMC.ActUnits, CostActCost=EMMC.ActCost, Asset=null, AmtTaken=0
    
    FROM EMMC with (NOLOCK)
   
   union all
   
   Select 'D',EMCD.EMCo,EMCD.EMGroup, EMCD.Equipment,EMCD.Mth,
          RevCode=null, CostCode=null, CostType=0, RevAvailableHrs=0,
          RevActualWorkUnits=0, RevActTime=0, RevActAmt=0,
          CostActualUnits=0, CostActCost=0, Asset=EMCD.Asset, AmtTaken=EMCD.Dollars
   
   
   
   FROM EMCD with (NOLOCK)
   where EMCD.EMTransType='Depn'
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMMthDeprCostRev] TO [public]
GRANT INSERT ON  [dbo].[brvEMMthDeprCostRev] TO [public]
GRANT DELETE ON  [dbo].[brvEMMthDeprCostRev] TO [public]
GRANT UPDATE ON  [dbo].[brvEMMthDeprCostRev] TO [public]
GO
