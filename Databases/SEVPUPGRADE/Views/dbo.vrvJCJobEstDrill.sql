SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  View vrvJCJobEstDrill    Script Date: 3/29/06 ******/
/******Replaces the JC Open Job Drilldown stored procedure  Report Title = JC Open Job Estimates Drilldown ******/
    
   CREATE  view [dbo].[vrvJCJobEstDrill]
          
     as
Select JCJP.JCCo, JCJP.Contract, JCJP.Item, JCJP.Job, JCJP.PhaseGroup, JCJP.Phase, 
       JCCH.CostType, CTAbbrev=JCCT.Abbreviation, JobStatus=Min(JCJM.JobStatus), JobDesc=Min(JCJM.Description),
       PhaseDesc=min(JCJP.Description), JCCHUM=JCCH.UM,CoName = HQCO.Name,
       OrigEstCost =  sum(JCCP.OrigEstCost),
       CurrEstHours = sum(JCCP.CurrEstHours),
       CurrEstUnits = sum(JCCP.CurrEstUnits),
       CurrEstItemUnits = case when JCCH.ItemUnitFlag='Y' then sum(JCCP.CurrEstUnits) else 0 end,
       CurrEstPhaseUnits = case when JCCH.PhaseUnitFlag='Y' then sum(JCCP.CurrEstUnits) else 0 end,
       CurrEstCost = sum(JCCP.CurrEstCost)
    
   FROM JCJP with(NoLock)
   Left Outer Join JCCH with(NoLock) on JCCH.JCCo=JCJP.JCCo and JCCH.Job=JCJP.Job and JCCH.PhaseGroup=JCJP.PhaseGroup
        and JCCH.Phase=JCJP.Phase 
   Left Outer Join JCCP with(NoLock) on JCCH.JCCo=JCCP.JCCo and JCCH.Job=JCCP.Job and JCCH.PhaseGroup=JCCP.PhaseGroup
        and JCCH.Phase=JCCP.Phase and JCCH.CostType=JCCP.CostType
   Join JCCT with(NoLock) on JCCT.PhaseGroup=JCCH.PhaseGroup and JCCT.CostType=JCCH.CostType
   Left Outer Join JCJM with (NOLOCK) on JCJP.JCCo = JCJM.JCCo and JCJP.Job = JCJM.Job   
   Join HQCO with(NoLock) on JCJP.JCCo = HQCO.HQCo
   
       
   group by JCJP.JCCo, JCJP.Job, JCJP.Phase, JCJP.PhaseGroup, JCCH.CostType, 
   JCCT.Abbreviation,JCCH.ItemUnitFlag,JCCH.PhaseUnitFlag, 
   JCCH.UM,JCJP.Contract, JCJP.Item,HQCO.Name


GO
GRANT SELECT ON  [dbo].[vrvJCJobEstDrill] TO [public]
GRANT INSERT ON  [dbo].[vrvJCJobEstDrill] TO [public]
GRANT DELETE ON  [dbo].[vrvJCJobEstDrill] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCJobEstDrill] TO [public]
GO
