SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE view [dbo].[brvEMRevenueCost] as
   
   select 
     Type= 'R',
     EMAR.EMCo,
     Category=EMEM.Category,
     CatDesc=EMCM.Description,
     EMAR.EMGroup,
     EMAR.Equipment,
     EquipDesc=EMEM.Description,
     EMAR.Month,
     FiscalPeriod=GLFP.FiscalPd,
     FiscalYear=GLFP.FiscalYr,
     EMAR.RevCode,
     EMEM.Department,
     RevCodeDesc=EMRC.Description,
     RevTimeUM=EMRC.TimeUM,
     EMAR.AvailableHrs,
     EMEM.Status,
     EMRC.Basis,
     EMAR.ActualWorkUnits,
     EMAR.Actual_Time,
     EMAR.ActualAmt,
     EMRC.HrsPerTimeUM,
     CostCode = '',
     CostCodeDesc='',
     CostType= '',
     CTAbbreviation='',
     CostUM='',
     CostActUnits = 0,
     CostActCost= 0,
     CoName='',
     BeginCategory='',
     EndCategory='',
     BeginEquip='',
     EndEquip='',
     BegMonth='01/01/2005',
     ThruMonth='12/01/2050'
      
   from EMAR 
      
         JOIN EMEM with(nolock) on EMEM.EMCo=EMAR.EMCo and EMEM.Equipment=EMAR.Equipment
         Join GLFP with(nolock) on GLFP.GLCo=EMAR.EMCo and GLFP.Mth=EMAR.Month
         Left Join EMCM with(nolock) on EMCM.EMCo=EMEM.EMCo and EMCM.Category=EMEM.Category
         Left Join EMRC with(nolock) on EMRC.EMGroup=EMAR.EMGroup and EMRC.RevCode=EMAR.RevCode
   
   UNION ALL
   
   select 
     Type= 'C',
     EMMC.EMCo,
     Category=EMEM.Category,
     CatDesc=EMCM.Description,
     EMMC.EMGroup,
     EMMC.Equipment,
     EquipDesc=EMEM.Description,
     EMMC.Month,
     FiscalPeriod=GLFP.FiscalPd,
     FiscalYear=GLFP.FiscalYr,
     '',
     EMEM.Department,
     RevCodeDesc='',
     RevTimeUM='',
     0,
     EMEM.Status,
     0,
     0,
     '',
     0,
     HrsPertimeUM='',
     CostCode = EMMC.CostCode,
     CostCodeDesc=EMCC.Description,
     CostType= EMMC.CostType,
     CTAbbreviation=EMCT.Abbreviation,
     CostUM=EMCH.UM,
     EMMC.ActUnits,
     EMMC.ActCost,
     CoName='',
     BeginCategory='',
     EndCategory='',
     BeginEquip='',
     EndEquip='',
     BegMonth='01/01/2005',
     ThruMonth='12/01/2050'
      
   from EMMC 
          JOIN EMEM with(nolock) on EMEM.EMCo=EMMC.EMCo and EMEM.Equipment=EMMC.Equipment
         Join GLFP with(nolock) on GLFP.GLCo=EMMC.EMCo and GLFP.Mth=EMMC.Month
         Left Join EMCM with(nolock) on EMCM.EMCo=EMMC.EMCo and EMCM.Category=EMEM.Category
         Left Join EMCC with(nolock) on EMCC.EMGroup=EMMC.EMGroup and EMCC.CostCode=EMMC.CostCode
         Left Join EMCT with(nolock) on EMCT.EMGroup=EMMC.EMGroup and EMCT.CostType=EMMC.CostType
         Left Join EMCH with(nolock) on EMCH.EMCo=EMMC.EMCo and EMCH.Equipment=EMMC.Equipment and EMCH.EMGroup=EMMC.EMGroup
      	 and EMCH.CostCode=EMMC.CostCode and EMCH.CostType=EMMC.CostType
   
   
   
   
   
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvEMRevenueCost] TO [public]
GRANT INSERT ON  [dbo].[brvEMRevenueCost] TO [public]
GRANT DELETE ON  [dbo].[brvEMRevenueCost] TO [public]
GRANT UPDATE ON  [dbo].[brvEMRevenueCost] TO [public]
GO
