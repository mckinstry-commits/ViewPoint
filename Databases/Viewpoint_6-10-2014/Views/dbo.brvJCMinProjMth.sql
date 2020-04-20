SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE   View [dbo].[brvJCMinProjMth]
   
   as
   
   select JCCP.JCCo, JCJP.Contract, JCJP.Item, MinProjMth=min(a.NextProjMth)
           From bJCCP JCCP With (NoLock)
           Join bJCJP JCJP With (NoLock) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
                     and JCJP.Phase=JCCP.Phase   
           Join (Select JCCP.JCCo, JCJP.Contract, JCJP.Item, NextProjMth=JCCP.Mth From JCCP With (NoLock)
                        Join bJCJP JCJP With (NoLock) on JCJP.JCCo=JCCP.JCCo and JCJP.Job=JCCP.Job and JCJP.PhaseGroup=JCCP.PhaseGroup
                                  and JCJP.Phase=JCCP.Phase 
                        Group By JCCP.JCCo, JCJP.Contract, JCJP.Item, Mth having sum(JCCP.ProjCost)<>0) as a 
                 on a.JCCo=JCCP.JCCo and a.Contract=JCJP.Contract and a.Item=JCJP.Item 
                    and a.NextProjMth=JCCP.Mth
                 Group By JCCP.JCCo, JCJP.Contract, JCJP.Item
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvJCMinProjMth] TO [public]
GRANT INSERT ON  [dbo].[brvJCMinProjMth] TO [public]
GRANT DELETE ON  [dbo].[brvJCMinProjMth] TO [public]
GRANT UPDATE ON  [dbo].[brvJCMinProjMth] TO [public]
GRANT SELECT ON  [dbo].[brvJCMinProjMth] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCMinProjMth] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCMinProjMth] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCMinProjMth] TO [Viewpoint]
GO
