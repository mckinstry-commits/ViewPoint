SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     View [dbo].[brvEMRevCost]
    --Drop view brvEMRevCost
    /***********************************************
      EM Revenue and Cost View 
      Created 3/5/2002 AA
    
     View performs two separate select statements for both the
     Revenue and Cost information. 
    
    Reports:  EM Revenue And Cost
   	   EM Revenue And Cost Comparison Report
              EM Revenue And Cost Comparison by Department
    
    *************************************************/
    
    as
    
    --Select Cost information
    
    select EMMC.EMCo, EMMC.Equipment, EMMC.Month, ActCost= sum(EMMC.ActCost), ActualAmt=null 
    From EMMC
    group by EMMC.EMCo, EMMC.Equipment, EMMC.Month
    
    union all
    
    --Select Revenue information
    
    select EMAR.EMCo, EMAR.Equipment, EMAR.Month,  ActCost=null, ActualAmt=sum(EMAR.ActualAmt) 
    From EMAR
    group by EMAR.EMCo, EMAR.Equipment, EMAR.Month,EMAR.AvailableHrs,EMAR.Actual_Time

GO
GRANT SELECT ON  [dbo].[brvEMRevCost] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevCost] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevCost] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevCost] TO [public]
GRANT SELECT ON  [dbo].[brvEMRevCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMRevCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMRevCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMRevCost] TO [Viewpoint]
GO
