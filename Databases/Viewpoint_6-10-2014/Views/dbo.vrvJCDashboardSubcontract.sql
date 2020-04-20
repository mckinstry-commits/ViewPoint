SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[vrvJCDashboardSubcontract] as
select JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, JCCH.Phase, JCCH.CostType, JCCH.BuyOutYN, 
          Estimated=JCCH.OrigCost, CommittedAmt=0,UnassignedAmt=0,RecType='JCCH'
   from JCCH 
   

   
   UNION ALL
   
   select PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, NULL, sum(PMOL.EstCost),
           CommittedAmt=0,UnassignedAmt=0, RecType='PMOL'
   from PMOL
   where PMOL.ACO is not NULL
   group by PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType
   
   UNION ALL
      
   select PMSL.PMCo, PMSL.Project, PMSL.PhaseGroup, PMSL.Phase, PMSL.CostType, NULL, 0, --PMSL.PCO, PMSL.ACO, PMSL.SL, PMSL.SubCO,
          CommittedAmt=(case when PMSL.PCO is not NULL and PMSL.ACO is NULL and PMSL.SubCO is NULL then 0
                              when PMSL.SL is not Null then  PMSL.Amount
                              else 0 end),
          UnassignedAmt=(case when PMSL.PCO is not NULL and PMSL.ACO is NULL and PMSL.SubCO is NULL then 0
                           when PMSL.SL is Null then  PMSL.Amount
                           else 0 end) ,RecType='PMSL'
   from PMSL
   --where PMSL.SL is not NULL

GO
GRANT SELECT ON  [dbo].[vrvJCDashboardSubcontract] TO [public]
GRANT INSERT ON  [dbo].[vrvJCDashboardSubcontract] TO [public]
GRANT DELETE ON  [dbo].[vrvJCDashboardSubcontract] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCDashboardSubcontract] TO [public]
GRANT SELECT ON  [dbo].[vrvJCDashboardSubcontract] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCDashboardSubcontract] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCDashboardSubcontract] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCDashboardSubcontract] TO [Viewpoint]
GO
