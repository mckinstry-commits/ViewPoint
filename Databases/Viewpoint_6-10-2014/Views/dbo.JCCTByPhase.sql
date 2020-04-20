SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of JC Cost Types by phase
   * unable to locate where used.
   *
   *****************************************/
   
   CREATE  view [dbo].[JCCTByPhase] as select JCCT.CostType, JCCT.Abbreviation,
   		OnPhase = case JCCH.CostType when null then '' else 'Y' end
   from dbo.JCCT
   left join dbo.JCCH on JCCH.CostType=JCCT.CostType and JCCH.PhaseGroup=JCCT.PhaseGroup


GO
GRANT SELECT ON  [dbo].[JCCTByPhase] TO [public]
GRANT INSERT ON  [dbo].[JCCTByPhase] TO [public]
GRANT DELETE ON  [dbo].[JCCTByPhase] TO [public]
GRANT UPDATE ON  [dbo].[JCCTByPhase] TO [public]
GRANT SELECT ON  [dbo].[JCCTByPhase] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCTByPhase] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCTByPhase] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCTByPhase] TO [Viewpoint]
GO
