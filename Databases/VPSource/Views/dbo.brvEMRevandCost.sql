SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[brvEMRevandCost]
   
   as
select Type='C',a.EMCo,Category=EMEM.Category,CatDesc=EMCM.Description,a.EMGroup,a.Equipment,EquipDesc=EMEM.Description,
      	a.Month,FiscalPeriod=GLFP.FiscalPd,FiscalYear=GLFP.FiscalYr, RevCode=Null, Department=EMEM.Department,
      	RevCodeDesc=Null,RevTimeUM=Null, RevAvailableHrs=0.00,
            	Status=EMEM.Status, Basis=Null, RevActualWorkUnits=0.00, RevActTime=0.00, RevActAmt=0.00, HrsPerTimeUM=0.00,
      
            	a.CostCode,CostCodeDesc=EMCC.Description,a.CostType,CTAbbreviation=EMCT.Abbreviation,
      	CostUM=EMCH.UM, CostActUnits=a.ActUnits, CostActCost=a.ActCost,
      
        CoName=HQCO.Name
      
         from EMMC a
      
         JOIN EMEM with(nolock) on EMEM.EMCo=a.EMCo and EMEM.Equipment=a.Equipment
         Join GLFP with(nolock) on GLFP.GLCo=a.EMCo and GLFP.Mth=a.Month
         Join EMCM with(nolock) on EMCM.EMCo=a.EMCo and EMCM.Category=EMEM.Category
         --Left Join EMRC with(nolock) on EMRC.EMGroup=a.EMGroup and EMRC.RevCode=a.RevCode
      
         Join EMCC with(nolock) on EMCC.EMGroup=a.EMGroup and EMCC.CostCode=a.CostCode
         Join EMCT with(nolock) on EMCT.EMGroup=a.EMGroup and EMCT.CostType=a.CostType
         Join EMCH with(nolock) on EMCH.EMCo=a.EMCo and EMCH.Equipment=a.Equipment and EMCH.EMGroup=a.EMGroup
      	 and EMCH.CostCode=a.CostCode and EMCH.CostType=a.CostType
         Join HQCO with(nolock) on HQCO.HQCo=a.EMCo
   
   UNION ALL
   
   select Type='R',a.EMCo,Category=EMEM.Category,CatDesc=EMCM.Description,a.EMGroup,a.Equipment,EquipDesc=EMEM.Description,
      	a.Month,FiscalPeriod=GLFP.FiscalPd,FiscalYear=GLFP.FiscalYr,a.RevCode, Department=EMEM.Department,
      	RevCodeDesc=EMRC.Description, RevTimeUM=EMRC.TimeUM, RevAvailableHrs=a.AvailableHrs,
            	EMEM.Status, EMRC.Basis, RevActualWorkUnits=a.ActualWorkUnits, RevActTime = a.Actual_Time, RevActAmt = a.ActualAmt ,
           EMRC.HrsPerTimeUM,
      
            	CostCode=Null,CostCodeDesc=Null, CostType=Null,CTAbbreviation=Null,
      	CostUM=Null, CostActUnits = Null , CostActCost=0.00,
      
        CoName=HQCO.Name
      
         from EMAR a
      
         JOIN EMEM with(nolock) on EMEM.EMCo=a.EMCo and EMEM.Equipment=a.Equipment
         Join GLFP with(nolock) on GLFP.GLCo=a.EMCo and GLFP.Mth=a.Month
         Join EMCM with(nolock) on EMCM.EMCo=a.EMCo and EMCM.Category=EMEM.Category
         Join EMRC with(nolock) on EMRC.EMGroup=a.EMGroup and EMRC.RevCode=a.RevCode
      
         --Left Join EMCC with(nolock) on EMCC.EMGroup=a.EMGroup and EMCC.CostCode=a.CostCode
         --Left Join EMCT with(nolock) on EMCT.EMGroup=a.EMGroup and EMCT.CostType=a.CostType
         --Left Join EMCH with(nolock) on EMCH.EMCo=a.EMCo and EMCH.Equipment=a.Equipment and EMCH.EMGroup=a.EMGroup
         -- and EMCH.CostCode=a.CostCode and EMCH.CostType=a.CostType
         Join HQCO with(nolock) on HQCO.HQCo=a.EMCo


GO
GRANT SELECT ON  [dbo].[brvEMRevandCost] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevandCost] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevandCost] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevandCost] TO [public]
GO
