SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE  View [dbo].[brvEMEqCatforEMTE]
    
    /***********************************************
      EMRR join to EMEM for Category
     
      Created 04/02/04 NF
    
      View enables linking EMTE to EMRR  EMEM.Category is required link
    
     Reports:   EM Revenue Template Report
    
    *************************************************/
    
    as
   
   select EMRR.EMCo, EMRR.Category, EMRR.RevCode, EMRR.EMGroup, EMRR.WorkUM, 
          EMRR.UpdtHrMeter, EMRR.PostWorkUnits, EMRR.AllowPostOride, EMRR.Rate, 
          EMEM.Equipment, EMEM.Description
   from EMRR 
   left outer join EMEM on 
   	EMEM.EMCo = EMRR.EMCo and 
   	EMEM.EMGroup = EMRR.EMGroup and 
   	EMRR.Category = EMEM.Category
   where EMEM.Equipment is not NULL
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMEqCatforEMTE] TO [public]
GRANT INSERT ON  [dbo].[brvEMEqCatforEMTE] TO [public]
GRANT DELETE ON  [dbo].[brvEMEqCatforEMTE] TO [public]
GRANT UPDATE ON  [dbo].[brvEMEqCatforEMTE] TO [public]
GRANT SELECT ON  [dbo].[brvEMEqCatforEMTE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMEqCatforEMTE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMEqCatforEMTE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMEqCatforEMTE] TO [Viewpoint]
GO
