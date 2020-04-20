SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 CREATE      view  [dbo].[brvJCInsPhase] as
   select Distinct HQCO.HQCo,HQCO.Name,JCCO.ValidPhaseChars,JCTN.JCCo,JCJM.Job,JCTI.InsTemplate,InsTempDesc=JCTN.Description,
        JCTI.PhaseGroup,TempPhase= left(JCTI.Phase,JCCO.ValidPhaseChars),JCTI.Phase,JCTI.InsCode,
        InsCodeDesc=HQIC.Description
    from JCTN JCTN
       Inner join JCJM JCJM ON (JCJM.JCCo=JCTN.JCCo) AND (JCJM.InsTemplate=JCTN.InsTemplate)
       Inner join HQCO HQCO ON (JCJM.JCCo=HQCO.HQCo)
       Inner join JCCO JCCO ON (JCTN.JCCo=JCCO.JCCo)
       Left join  JCTI JCTI ON (JCTI.JCCo=JCTN.JCCo) AND (JCTI.InsTemplate=JCTN.InsTemplate)
       Inner join HQIC HQIC ON (JCTI.InsCode=HQIC.InsCode)
 
 



GO
GRANT SELECT ON  [dbo].[brvJCInsPhase] TO [public]
GRANT INSERT ON  [dbo].[brvJCInsPhase] TO [public]
GRANT DELETE ON  [dbo].[brvJCInsPhase] TO [public]
GRANT UPDATE ON  [dbo].[brvJCInsPhase] TO [public]
GRANT SELECT ON  [dbo].[brvJCInsPhase] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCInsPhase] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCInsPhase] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCInsPhase] TO [Viewpoint]
GO
