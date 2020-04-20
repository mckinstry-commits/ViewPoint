SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvJobData]
AS
SELECT JCCP.JCCo, JCCP.Job, JCJM.Description AS JDesc, JCCP.Phase, JCJP.Description AS Description1, 
	sum(JCCP.ActualHours) AS SumOfActualHours, sum(JCCP.CurrEstHours) AS SumOfCurrEstHours, 
	sum(JCCP.ActualUnits) AS SumOfActualUnits, sum(JCCP.CurrEstUnits) AS SumOfCurrEstUnits, 
	sum(JCCP.ActualCost) AS SumOfActualCost, sum(JCCP.CurrEstCost) AS SumOfCurrEstCost

FROM JCCP with (nolock) 
	INNER JOIN JCJP with (nolock) ON JCCP.JCCo = JCJP.JCCo AND JCCP.Phase = JCJP.Phase AND 
	JCCP.PhaseGroup = JCJP.PhaseGroup AND JCCP.Job = JCJP.Job
	INNER JOIN JCJM with (nolock) ON JCCP.JCCo = JCJM.JCCo AND JCCP.Job = JCJM.Job

WHERE JCJP.ActiveYN='Y' and JCJM.JobStatus=1	

GROUP BY JCCP.JCCo, JCCP.Job, JCJM.Description, JCCP.Phase, JCJP.Description

GO
GRANT SELECT ON  [dbo].[ptvJobData] TO [public]
GRANT INSERT ON  [dbo].[ptvJobData] TO [public]
GRANT DELETE ON  [dbo].[ptvJobData] TO [public]
GRANT UPDATE ON  [dbo].[ptvJobData] TO [public]
GO
