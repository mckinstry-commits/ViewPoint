SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE      View [dbo].[brvEMDeprExpAcct] as
    /******************************************
    
    EM Deprecation Expense Account 
    created 5/9/03 CR
    
    View will find Depreciation Expense Account if the Account is not assigned on the Asset Setup form.
    
    Reports:  EMAssetSetup.rpt, EMMTDYTDDeprSchedule.rpt, EMAssetsGLAcct.rpt
    
    *******************************************/
    
    select EMCO=EMDM.EMCo, Dept=EMDM.Department, GLCo=EMDM.GLCo, EMDM.DepreciationAcct, EMDOCostCode.CostCode, EMDGCostType.CostType,
    EMDOAcct=EMDOCostCode.GLAcct,EMDGAcct=EMDGCostType.GLAcct from EMDM
    
    
    Left Join (Select EMDO.EMCo, EMDO.Department, EMDO.CostCode, EMDO.EMGroup, EMDO.GLCo, EMDO.GLAcct from EMDO
       Inner Join EMCO on EMDO.EMCo=EMCO.EMCo and EMDO.EMGroup=EMCO.EMGroup and EMCO.DeprCostCode=EMDO.CostCode) as 
       EMDOCostCode on EMDOCostCode.EMCo=EMDM.EMCo and EMDOCostCode.Department=EMDM.Department 
    
    Left Join (Select EMDG.EMCo, EMDG.Department, EMDG.CostType,EMDG.EMGroup,EMDG.GLCo, EMDG.GLAcct from EMDG
       Inner Join EMCO on EMDG.EMCo=EMCO.EMCo and EMDG.EMGroup=EMCO.EMGroup
       and  EMCO.DeprCostType=EMDG.CostType) as 
       EMDGCostType on EMDGCostType.EMCo=EMDM.EMCo and EMDGCostType.Department=EMDM.Department
    
    
    
    
    
    
    
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMDeprExpAcct] TO [public]
GRANT INSERT ON  [dbo].[brvEMDeprExpAcct] TO [public]
GRANT DELETE ON  [dbo].[brvEMDeprExpAcct] TO [public]
GRANT UPDATE ON  [dbo].[brvEMDeprExpAcct] TO [public]
GRANT SELECT ON  [dbo].[brvEMDeprExpAcct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvEMDeprExpAcct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvEMDeprExpAcct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvEMDeprExpAcct] TO [Viewpoint]
GO
