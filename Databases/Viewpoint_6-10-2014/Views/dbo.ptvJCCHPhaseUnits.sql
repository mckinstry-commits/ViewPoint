SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[ptvJCCHPhaseUnits]
AS

-- JC Cost Header (Active Cost types by Job/Phase)
-- to indicate which Jobs to send to PowerTrack
-- Restrict in PT by Phase, Job and JC Company

SELECT JCCH.CostType, JCCT.Description, JCCH.UM, JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, 
	JCCH.Phase, SUM (ActualUnits)as 'Units Complete'

FROM JCCP
	Inner Join JCCH with (nolock) ON (JCCH.CostType=JCCP.CostType) AND (JCCH.Phase=JCCP.Phase) AND (JCCH.JCCo=JCCP.JCCo) AND 
	(JCCH.Job=JCCP.Job) AND (JCCH.PhaseGroup=JCCP.PhaseGroup) 
	INNER JOIN JCJM with (nolock) ON (JCCH.Job=JCJM.Job) AND (JCCH.JCCo=JCJM.JCCo) 
	INNER JOIN JCJP with (nolock) ON (JCCH.Phase=JCJP.Phase) AND (JCCH.JCCo=JCJP.JCCo) AND 
	(JCCH.Job=JCJP.Job) AND (JCCH.PhaseGroup=JCJP.PhaseGroup) 
	INNER JOIN JCCT with (nolock) ON (JCCH.CostType=JCCT.CostType) AND (JCCH.PhaseGroup=JCCT.PhaseGroup)

where (JCJM.JobStatus)=1 AND (JCJP.ActiveYN)='Y' AND (JCCH.ActiveYN)='Y' and JCCH.PhaseUnitFlag='Y'

Group By JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, JCCH.Phase,JCCH.CostType, JCCT.Description, JCCH.UM

GO
GRANT SELECT ON  [dbo].[ptvJCCHPhaseUnits] TO [public]
GRANT INSERT ON  [dbo].[ptvJCCHPhaseUnits] TO [public]
GRANT DELETE ON  [dbo].[ptvJCCHPhaseUnits] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCCHPhaseUnits] TO [public]
GRANT SELECT ON  [dbo].[ptvJCCHPhaseUnits] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvJCCHPhaseUnits] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvJCCHPhaseUnits] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvJCCHPhaseUnits] TO [Viewpoint]
GO
