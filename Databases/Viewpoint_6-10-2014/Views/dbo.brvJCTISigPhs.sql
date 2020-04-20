SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[brvJCTISigPhs] as

/********************************
removed the JCTI.InsCode from the Group By CR issue #123893

used in the JC Insurance Template by  Job Phase report
********************************/
select  JCTI.JCCo,JCTI.InsTemplate,JCTI.PhaseGroup,SigPhase=left(JCTI.Phase,JCCO.ValidPhaseChars), 
         FirstPhase=min(JCTI.Phase)
    From JCTI
    Join JCCO on JCCO.JCCo=JCTI.JCCo
 
 Group By  JCTI.JCCo, JCTI.InsTemplate, JCTI.PhaseGroup,left(JCTI.Phase,JCCO.ValidPhaseChars)--,JCTI.InsCode

GO
GRANT SELECT ON  [dbo].[brvJCTISigPhs] TO [public]
GRANT INSERT ON  [dbo].[brvJCTISigPhs] TO [public]
GRANT DELETE ON  [dbo].[brvJCTISigPhs] TO [public]
GRANT UPDATE ON  [dbo].[brvJCTISigPhs] TO [public]
GRANT SELECT ON  [dbo].[brvJCTISigPhs] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCTISigPhs] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCTISigPhs] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCTISigPhs] TO [Viewpoint]
GO
