SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE View [dbo].[viDim_JCJobPhases]

/**************************************************
 * Alterd: DH 6/26/08
 * Modified:      
 * Usage:  Selects Phases from both Job Phases and Phase Master for use 
 *         as a dimension in SSAS Cubes.  Uses CTE's to find appropriate
 *         master phase from JCPM.  
           Master Phase:If JCJP record exists without exact phase code
 *         in JCPM, then gets the valid phase code (i.e. 00650-100 in JCJP, selects
 *         00650- from JCPM).  Otherwise, select matching phase code from JCPM.
 * 
 ***************************************************/

as

/**Select bJCJP Description fields into this CTE due to performance issues during Cube Processing**/

With JobPhases
  (JCCo
   ,PhaseGroup
   ,Job
   ,JobID
   ,JobAndDescription		
   ,Phase
   ,PhaseUM
   ,JobPhaseID
   ,JobPhaseDescription
   ,JobPhaseCostType
   ,JobPhaseCostTypeID
   ,CostTypeID
   ,CostTypeDescription	
   ,CostTypeUM	
   ,PhasePart1
   )
as (select  bJCCO.JCCo
           ,bJCJP.PhaseGroup
		   ,bJCJP.Job
           ,bJCJM.KeyID as JobID
		   ,bJCJM.Description as JobAndDescription	
           ,bJCJP.Phase
           ,case when bJCCH.PhaseUnitFlag = 'Y' then bJCCH.UM end as PhaseUM
		   ,bJCJP.KeyID
		   ,bJCJP.Description as JobPhaseDescription
		   ,bJCCH.CostType 
		   ,bJCCH.KeyID as JobPhaseCostTypeID
	       ,bJCCT.KeyID as CostTypeID
	       ,bJCCT.Description as CostTypeDescription	
	       ,bJCCH.UM as CostTypeUM
		   ,Left(bJCJP.Phase,bJCCO.ValidPhaseChars) as PhasePart1
    From bJCCH With (NoLock)
    Join vDDBICompanies With (NoLock) on vDDBICompanies.Co=bJCCH.JCCo
	Join bJCCT With (NoLock) on bJCCT.PhaseGroup=bJCCH.PhaseGroup and bJCCT.CostType=bJCCH.CostType
    Join bJCJP With (NoLock) on bJCJP.JCCo=bJCCH.JCCo and bJCJP.Job=bJCCH.Job
							and bJCJP.PhaseGroup=bJCCH.PhaseGroup and bJCJP.Phase=bJCCH.Phase
    Join bJCJM With (NoLock) on bJCJM.JCCo=bJCCH.JCCo and bJCJM.Job=bJCCH.Job
    Join bJCCO With (NoLock) on bJCCO.JCCo=bJCCH.JCCo
   ),

/*PhasePartCount CTE:  Select each First Part of Phase (PhasePart1) from JCPM
 * Select the first full phase code by PhasePart1 (FirstPhase)*/
PhasePartCount (JCCo, PhaseGroup, PhasePart1, FirstPhase)
as (select bJCCO.JCCo,
		   bJCPM.PhaseGroup,
	       Left(bJCPM.Phase,bJCCO.ValidPhaseChars),
		   min(bJCPM.Phase) as FirstPhase
     From bJCPM With (NoLock)
     Join bHQCO With (NoLock) on bHQCO.PhaseGroup=bJCPM.PhaseGroup
	 Join bJCCO With (NoLock) on bJCCO.JCCo=bHQCO.HQCo
	 Group By bJCCO.JCCo,
		   bJCPM.PhaseGroup,
	       Left(bJCPM.Phase,bJCCO.ValidPhaseChars)
    ),

/*Join PhasePartCount on valid part of phase to get first JCPM phase linked to JCJP Phase*/
JobPhases2
(JCCo
 ,Job
 ,JobID
 ,JobAndDescription
 ,PhaseGroup
 ,JobPhase
 ,PhaseUM
 ,JobPhaseID
 ,JobPhaseDescription
 ,JobPhaseCostType
 ,JobPhaseCostTypeID
 ,CostTypeID
 ,CostTypeDescription
 ,CostTypeUM
 ,MasterPhase
 )
as (select  JobPhases.JCCo,
           JobPhases.Job,
           JobPhases.JobID,
		   JobPhases.JobAndDescription, 
		   JobPhases.PhaseGroup,
           JobPhases.Phase,
           JobPhases.PhaseUM,
		   JobPhases.JobPhaseID,
		   JobPhases.JobPhaseDescription,
		   JobPhases.JobPhaseCostType,
		   JobPhases.JobPhaseCostTypeID,
	       JobPhases.CostTypeID,
		   JobPhases.CostTypeDescription,
		   JobPhases.CostTypeUM,	
		   PhasePartCount.FirstPhase
	From JobPhases With (NoLock)
    Left Join PhasePartCount With (NoLock) on PhasePartCount.JCCo=JobPhases.JCCo 
						and PhasePartCount.PhaseGroup=JobPhases.PhaseGroup
						and PhasePartCount.PhasePart1=JobPhases.PhasePart1)

/*Final Select*/
Select 
       JobPhases2.JobPhaseID
	  ,JobPhases2.JCCo
	  ,bJCCO.KeyID as JCCoID
	  ,JobPhases2.JobID
	  ,JobPhases2.Job
	  ,JobPhases2.Job+' '+isnull(JobPhases2.JobAndDescription,'') as JobAndDescription
      ,JobPhases2.PhaseGroup
	  ,JobPhases2.JobPhase
	  ,JobPhases2.JobPhase+' '+isnull(JobPhases2.JobPhaseDescription,'') as JobPhaseAndDescription
	  ,JobPhases2.PhaseUM
	  ,bJCPM.KeyID as MasterPhaseID
	  ,bJCPM.Phase+' '+isnull(bJCPM.Description,'') as MasterPhaseAndDescription
	  ,JobPhases2.JobPhaseCostTypeID
	  ,JobPhases2.JobPhaseCostType
      ,JobPhases2.CostTypeID
	  ,JobPhases2.CostTypeDescription
	  ,JobPhases2.CostTypeUM
	  	  --,bJCCT.KeyID as CostTypeID
	  --,bJCCT.Description as CostTypeDescription  	 
	  From JobPhases2 With (NoLock)
/*Join bJCJP With (NoLock) on bJCJP.JCCo=JobPhases2.JCCo and bJCJP.Job=JobPhases2.Job
							and bJCJP.PhaseGroup=JobPhases2.PhaseGroup and bJCJP.Phase=JobPhases2.JobPhase*/
Join bJCCO With (NoLock) on bJCCO.JCCo=JobPhases2.JCCo
Join vDDBICompanies With (NoLock) on vDDBICompanies.Co=JobPhases2.JCCo
--Join bJCJM With (NoLock) on bJCJM.JCCo=JobPhases2.JCCo and bJCJM.Job=JobPhases2.Job
--Join bJCCT With (NoLock) on bJCCT.PhaseGroup=JobPhases2.PhaseGroup and bJCCT.CostType=JobPhases2.JobPhaseCostType	
Left Join bJCPM With (NoLock) on bJCPM.PhaseGroup=JobPhases2.PhaseGroup and bJCPM.Phase=JobPhases2.MasterPhase

union all

Select 
        0 --JobPhaseID
	  , null --JobPhases2.JCCo
	  , 0 --JCCoID
	  , 0 --JobID
	  , null --Job
	  , null --JobAndDescription
      , null --PhaseGroup
	  , null --JobPhase
	  , null --JobPhaseUM
	  , 'Unassigned' -- JobPhaseAndDescription
	  , 0 --MasterPhaseID
	  , null -- MasterPhaseAndDescription
	  , 0 --JobPhaseCostTypeID
	  , null --JobPhaseCostType
      , 0 --CostTypeID
	  , null --CostTypeDescription
	  , null --CostTypeUM







GO
GRANT SELECT ON  [dbo].[viDim_JCJobPhases] TO [public]
GRANT INSERT ON  [dbo].[viDim_JCJobPhases] TO [public]
GRANT DELETE ON  [dbo].[viDim_JCJobPhases] TO [public]
GRANT UPDATE ON  [dbo].[viDim_JCJobPhases] TO [public]
GRANT SELECT ON  [dbo].[viDim_JCJobPhases] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_JCJobPhases] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_JCJobPhases] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_JCJobPhases] TO [Viewpoint]
GO
