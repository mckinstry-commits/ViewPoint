SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC Job Active phase
   * unable to locate where used.
   *
   *****************************************/
   
   CREATE   view [dbo].[JCCHSinglePhase] as 
   select JCCo, Job, PhaseGroup, Phase, CostType, ActiveYN
   from dbo.JCCH where ActiveYN='Y'

GO
GRANT SELECT ON  [dbo].[JCCHSinglePhase] TO [public]
GRANT INSERT ON  [dbo].[JCCHSinglePhase] TO [public]
GRANT DELETE ON  [dbo].[JCCHSinglePhase] TO [public]
GRANT UPDATE ON  [dbo].[JCCHSinglePhase] TO [public]
GO
