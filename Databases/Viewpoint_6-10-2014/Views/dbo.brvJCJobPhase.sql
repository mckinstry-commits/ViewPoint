SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 CREATE     view [dbo].[brvJCJobPhase] as
 select Distinct HQCO.HQCo,HQCO.Name,JCCO.ValidPhaseChars,JCJM.JCCo,JCJM.Job,JobDesc=JCJM.Description,JCJM.JobStatus,
        JCJM.InsTemplate,InsTempDesc=JCTN.Description,JCJP.PhaseGroup,JobPhase= left(JCJP.Phase,JCCO.ValidPhaseChars),
        JCJP.Phase,JCJP.InsCode, HQIC.Description, PhsDesc=JCJP.Description,JCJP.ActiveYN
    from JCJM JCJM 
       Inner join JCJP JCJP ON ((JCJM.JCCo=JCJP.JCCo)AND(JCJM.Job=JCJP.Job))AND(JCJM.Contract=JCJP.Contract)
       Inner join JCCO JCCO ON (JCJM.JCCo=JCCO.JCCo)
       Inner join HQCO HQCO ON (JCJM.JCCo=HQCO.HQCo)
       Inner join JCTN JCTN ON (JCJM.JCCo=JCTN.JCCo) AND (JCJM.InsTemplate=JCTN.InsTemplate)
	   Left join HQIC HQIC	ON JCJP.InsCode = HQIC.InsCode





 
 



GO
GRANT SELECT ON  [dbo].[brvJCJobPhase] TO [public]
GRANT INSERT ON  [dbo].[brvJCJobPhase] TO [public]
GRANT DELETE ON  [dbo].[brvJCJobPhase] TO [public]
GRANT UPDATE ON  [dbo].[brvJCJobPhase] TO [public]
GRANT SELECT ON  [dbo].[brvJCJobPhase] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCJobPhase] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCJobPhase] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCJobPhase] TO [Viewpoint]
GO
