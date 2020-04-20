SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ptvJCJM]
AS

-- JC Job master
-- Uncomment second part of where clause if using a user memo 
-- to indicate which Jobs to send to PowerTrack
-- Restrict in PT by JC Company

SELECT Substring(Isnull(j.Description,' ') +'                             ',1,27-InputLength)+' * '+Job as 'JobCombined', j.Job, j.Description, j.JCCo

FROM JCJM j with (nolock)
inner join DDDTShared with (nolock) on Datatype='bJob'

WHERE (((j.JobStatus)=1)) 
--	And j.udPT='Y'


GO
GRANT SELECT ON  [dbo].[ptvJCJM] TO [public]
GRANT INSERT ON  [dbo].[ptvJCJM] TO [public]
GRANT DELETE ON  [dbo].[ptvJCJM] TO [public]
GRANT UPDATE ON  [dbo].[ptvJCJM] TO [public]
GRANT SELECT ON  [dbo].[ptvJCJM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ptvJCJM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ptvJCJM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ptvJCJM] TO [Viewpoint]
GO
