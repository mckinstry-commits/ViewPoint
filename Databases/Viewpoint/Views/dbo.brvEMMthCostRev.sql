SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object View .brvEMMthCostRev    Script Date: 04/28/2004******/
   /* View created to replace brptEMMthCostRev, and is used by the EM Monthly Cost and Revenue DD*/
   
      CREATE  View  [dbo].[brvEMMthCostRev] as
   
   /* insert Revenue info */
   
   select
   
   Type=  '1R',
   EMCo=  EMAR.EMCo,
   EMGroup = EMAR.EMGroup,
   Equipment = EMAR.Equipment,
   Month = EMAR.Month,
   RevCode = EMAR.RevCode,
   RevAvailableHrs = EMAR.AvailableHrs,
   RevActualWorkUnits = EMAR.ActualWorkUnits,
   RevActTime = EMAR.Actual_Time,
   RevActAmt = EMAR.ActualAmt,
   CostCode = NULL,
   CostType = NULL,
   CostActUnits = NULL,
   CostActCost =  NULL
   	
   FROM EMAR
   
   UNION ALL
   
     /* insert Cost info */
   select 
   	'2C',
   	EMCo,
   	EMGroup,
   	Equipment,
   	Month,
   	NULL, 
   	NULL, 
   	NULL, 
   	NULL, 
   	NULL,
   	CostCode,
   	CostType ,
   	ActUnits,
   	ActCost 
   
     FROM EMMC
    
   
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMMthCostRev] TO [public]
GRANT INSERT ON  [dbo].[brvEMMthCostRev] TO [public]
GRANT DELETE ON  [dbo].[brvEMMthCostRev] TO [public]
GRANT UPDATE ON  [dbo].[brvEMMthCostRev] TO [public]
GO
