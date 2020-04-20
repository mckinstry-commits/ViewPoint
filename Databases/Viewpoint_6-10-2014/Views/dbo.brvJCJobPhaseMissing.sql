SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view  [dbo].[brvJCJobPhaseMissing] as
   
  select j.JCCo, j.Job,j.JobDesc,j.PhaseGroup,j.JobPhase,j.Phase,j.PhsDesc,j.ActiveYN,j.InsTemplate,j.InsTempDesc
       From brvJCJobPhase j 
    Where  not exists (select Job From brvJCInsPhase i 
    Where j.JCCo=i.JCCo and j.Job=i.Job and j.PhaseGroup=i.PhaseGroup and j.JobPhase=i.TempPhase
          and j.InsTemplate=i.InsTemplate)

GO
GRANT SELECT ON  [dbo].[brvJCJobPhaseMissing] TO [public]
GRANT INSERT ON  [dbo].[brvJCJobPhaseMissing] TO [public]
GRANT DELETE ON  [dbo].[brvJCJobPhaseMissing] TO [public]
GRANT UPDATE ON  [dbo].[brvJCJobPhaseMissing] TO [public]
GRANT SELECT ON  [dbo].[brvJCJobPhaseMissing] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCJobPhaseMissing] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCJobPhaseMissing] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCJobPhaseMissing] TO [Viewpoint]
GO
