SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE      View [dbo].[brvEMRevBdownCost]
    /*******
     Created By:  TL 5/20/02
     Modified By: DH 7/10/02 Issue 17901
     Modified by: CR 10/17/03 Issue #21469 (added EMRD.WorkUnits)
     Usage:  View combines EM Revenue and Cost information.  Used by the
             EM Revenue Breakdown Cost Report
    
    ********/
    
    as
    /* insert Revenue info */
    Select EMRB.EMCo,EMRB.EMGroup, EMRB.Equipment, EMRB.RevBdownCode, EMRB.RevCode, EMRB.Mth, EMRB.Trans, RevBAmount=EMRB.Amount,
    TimeUnits = EMRD.TimeUnits, WorkUnits = EMRD.WorkUnits,/*Dollars = 0,*/ EMCostCode = '',EMCostType = 0,CostUnits = 0, CostDollars=0,Rectype = 'A'
    From EMRB
    Join EMRD on EMRD.EMCo=EMRB.EMCo and EMRD.Mth=EMRB.Mth and EMRD.Trans=EMRB.Trans
     
    /*Union All*/
    
    /* insert Revenue Detail info */
    /*Select a.EMCo, a.EMGroup,a.Equipment,b.RevBdownCode,a.RevCode,
    a.Mth,a.Trans,0,a.TimeUnits,a.Dollars,
    a.EMCostCode,a.EMCostType,0,0,'A'
    FROM   EMRD a
    inner Join EMRB b on a.EMCo = b.EMCo and a.EMGroup = b.EMGroup and a.Equipment = b.Equipment
    	and a.Mth = b.Mth and a.Trans = b.Trans and a.RevCode = b.RevCode*/
    
    
    Union all
    
    /* insert Cost info */
    Select a.EMCo,a.EMGroup,a.Equipment,b.RevBdownCode,null,a.Mth,a.EMTrans,0,0,0,/*0,*/
    a.CostCode,a.EMCostType,a.Units, a.Dollars,'B'
    From EMCD a
    inner Join EMCC b on a.EMGroup = b.EMGroup and a.CostCode= b.CostCode
    
    
    
    
    
    
    
    
    
    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMRevBdownCost] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevBdownCost] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevBdownCost] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevBdownCost] TO [public]
GRANT SELECT ON  [dbo].[brvEMRevBdownCost] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMRevBdownCost] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMRevBdownCost] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMRevBdownCost] TO [Viewpoint]
GO
