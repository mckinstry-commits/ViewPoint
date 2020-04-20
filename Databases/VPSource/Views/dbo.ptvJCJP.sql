SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvJCJP]
AS

-- JC Job Phases (Active Phases for a Job)
-- Uncomment second part of where clause if using a user memo 
-- to indicate which Jobs to send to PowerTrack
-- Restrict in PT by Job and JC Company

SELECT JCJP.Phase, JCJP.Description, JCJP.JCCo, JCJP.Job, JCJP.PhaseGroup

FROM JCJP with (nolock) 
	INNER JOIN JCJM with (nolock) ON (JCJP.JCCo = JCJM.JCCo)
	 and (JCJP.Job = JCJM.Job)														-- add Job to join

WHERE (((JCJM.JobStatus)=1) AND ((JCJP.ActiveYN)='Y')) 
--	And JCJM.udPT='Y'

GO
GRANT SELECT ON  [dbo].[ptvJCJP] TO [public]
GRANT INSERT ON  [dbo].[ptvJCJP] TO [public]
GRANT DELETE ON  [dbo].[ptvJCJP] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCJP] TO [public]
GO
