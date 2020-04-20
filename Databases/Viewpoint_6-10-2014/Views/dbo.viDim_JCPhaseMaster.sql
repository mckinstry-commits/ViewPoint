SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_JCPhaseMaster]

/**************************************************
 * Alterd: DH 7/9/08
 * Modified:      
 * Usage:  Selects Phases from Phase Master for use as a Dimension
 *         in SSAS Cubes.  MasterPhaseID derived from viDim_JCPhases,
 *         which is linked viFact_JCDetail.  MasterPhaseID in this view 
 *         used only for linking in SSAS.
 ***************************************************/

as

With JobPhases (JCCo, PhaseGroup, Job, Phase, PhasePart1)
as (select distinct bJCCO.JCCo
           ,bJCJP.PhaseGroup
		   ,bJCJP.Job
           ,bJCJP.Phase
		   ,Left(bJCJP.Phase,bJCCO.ValidPhaseChars) as PhasePart1
    From bJCJP With (NoLock)
    Join bJCCO With (NoLock) on bJCCO.JCCo=bJCJP.JCCo
   ),

/*PhasePartCount CTE:  Select each First Part of Phase (PhasePart1) from JCPM
 * Select the first full phase code by PhasePart1 (FirstPhase)*/
PhasePartCount (JCCo, PhaseGroup, PhasePart1, FirstPhase)
as (select bJCCO.JCCo,
		   bJCPM.PhaseGroup,
	       Left(bJCPM.Phase,bJCCO.ValidPhaseChars),
		   min(bJCPM.Phase) as FirstPhase
     From bJCPM
     Join bHQCO on bHQCO.PhaseGroup=bJCPM.PhaseGroup
	 Join bJCCO on bJCCO.JCCo=bHQCO.HQCo
	 Group By bJCCO.JCCo,
		   bJCPM.PhaseGroup,
	       Left(bJCPM.Phase,bJCCO.ValidPhaseChars)
    ),

/*Select either Phase from JCPM if exists or the FirstPhase from PhasePartCount*/
JobPhases2 (JCCo, Job, PhaseGroup, JobPhase, MasterPhase)
as (select  JobPhases.JCCo,
           JobPhases.Job,
		   JobPhases.PhaseGroup,
           JobPhases.Phase,
		   PhasePartCount.FirstPhase
	From JobPhases
    Join PhasePartCount on PhasePartCount.JCCo=JobPhases.JCCo 
						and PhasePartCount.PhaseGroup=JobPhases.PhaseGroup
						and PhasePartCount.PhasePart1=JobPhases.PhasePart1)

Select min(bJCPM.KeyID) as MasterPhaseID,
	   JobPhases2.PhaseGroup,
	   JobPhases2.JobPhase as Phase,
       min(bJCPM.Phase)+' '+isnull(min(bJCPM.Description),'') as MasterPhaseAndDescription
From JobPhases2
Join bJCPM With (NoLock) on bJCPM.PhaseGroup=JobPhases2.PhaseGroup and bJCPM.Phase=JobPhases2.MasterPhase
Group by JobPhases2.PhaseGroup,
	     JobPhases2.JobPhase

union all

Select 0 as MasterPhaseID,
	   Null as PhaseGroup,
	   Null as Phase,
		    'Blank' as MasterPhaseAndDescription
	  
From bJCPM With (NoLock)

GO
GRANT SELECT ON  [dbo].[viDim_JCPhaseMaster] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCPhaseMaster] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCPhaseMaster] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCPhaseMaster] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCPhaseMaster] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCPhaseMaster] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCPhaseMaster] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCPhaseMaster] TO [Viewpoint]
GO
