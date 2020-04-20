SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvJCCH]
AS

-- JC Cost Header (Active Cost types by Job/Phase)
-- Uncomment second part of having clause if using a user memo 
-- to indicate which Jobs to send to PowerTrack
-- Restrict in PT by Phase, Job and JC Company

SELECT JCCH.CostType, JCCT.Description, JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, 
	JCCH.Phase, JCJM.JobStatus, JCJP.ActiveYN, JCCH.ActiveYN AS ActiveYN1, JCCH.UM, 
	JCCH.PhaseUnitFlag AS "Phase Units"

FROM JCCH with (nolock)
	INNER JOIN JCJM with (nolock) ON (JCCH.Job=JCJM.Job) AND (JCCH.JCCo=JCJM.JCCo) 
	INNER JOIN JCJP with (nolock) ON (JCCH.Phase=JCJP.Phase) AND (JCCH.JCCo=JCJP.JCCo) AND 
	(JCCH.Job=JCJP.Job) AND (JCCH.PhaseGroup=JCJP.PhaseGroup) 
	INNER JOIN JCCT with (nolock) ON (JCCH.CostType=JCCT.CostType) AND (JCCH.PhaseGroup=JCCT.PhaseGroup)

where (JCJM.JobStatus)=1 AND (JCJP.ActiveYN)='Y' AND (JCCH.ActiveYN)='Y'

GO
GRANT SELECT ON  [dbo].[ptvJCCH] TO [public]
GRANT INSERT ON  [dbo].[ptvJCCH] TO [public]
GRANT DELETE ON  [dbo].[ptvJCCH] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCCH] TO [public]
GO
