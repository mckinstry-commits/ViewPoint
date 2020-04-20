SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnDetailedJobCost_LWO]
(
	@Company bCompany 
,	@Job  bJob	=null
)
RETURNS TABLE 
AS

RETURN

SELECT 
	t1.JCCo
,	t1.Mth
,	t1.Job
,	t5.Description AS JobDesc
,	t1.Phase
,	t3.Description AS PhaseDesc
--,	t1.EarnType
,	t2.Abbreviation  AS CostTypeAbbrev
,	t2.Description AS CostTypeDesc
,	t1.PostedDate
,	t1.ActualDate	
,	CAST((SUM(t1.ActualCost)/count(t5.KeyID)) AS DECIMAL(20,2)) AS Cost
,	t1.PRCo
,	t1.Employee
,	t6.LastName + ',' + t6.FirstName AS EmployeeName
,	CASE  
	WHEN t1.EarnType=5 THEN SUM(t1.ActualHours)
	WHEN t1.EarnType IS null THEN SUM(t1.ActualHours)
	ELSE 0
	END AS 'RG'
,	CASE  
	WHEN t1.EarnType=6 THEN SUM(t1.ActualHours)
	ELSE 0
	END AS 'OV'
,	CASE  
	WHEN t1.EarnType NOT IN (5,6) THEN SUM(t1.ActualHours)	
	ELSE 0
	END AS 'OT'		
,	SUM(t1.ActualHours) AS Hours
--,	MAX(t1.DetlDesc) AS DetlDesc
--,	count(t5.KeyID) AS T5Count
--,	count(t2.KeyID) AS T2Count
--,	count(t3.KeyID) AS T3Count
--,	count(t1.KeyID) AS T1Count
FROM 
	brvJCCDDetlDesc t1 JOIN
	JCJM t5 ON
		t1.JCCo=t5.JCCo
	AND t1.Job=t5.Job JOIN
	JCCT t2 ON
		t1.JCCo=t5.JCCo
	AND	t1.PhaseGroup=t2.PhaseGroup
	AND t1.CostType=t2.CostType	JOIN
	JCJP t3 ON
		t1.JCCo=t3.JCCo
	AND t1.Job=t3.Job
    AND t1.PhaseGroup=t3.PhaseGroup
	AND t1.Phase=t3.Phase  LEFT OUTER JOIN
	HQET t4 ON
		t1.EarnType=t4.EarnType	LEFT OUTER JOIN
	dbo.PREH t6 ON
		t1.PRCo=t6.PRCo
	AND t1.Employee=t6.Employee
WHERE
	(t1.JCCo=@Company )
AND	(t1.Job=@Job OR @Job IS null)
GROUP BY
	t1.JCCo
,	t1.Mth
,	t1.Job
,   t5.Description
,	t1.Phase
,	t3.Description
,	t1.EarnType
,	t2.Abbreviation 
,	t2.Description
,	t1.PostedDate
,	t1.ActualDate
,	t4.Description
,	t1.PRCo
,	t1.Employee
,	t6.LastName + ',' + t6.FirstName
HAVING
	( SUM(t1.ActualHours) <> 0 OR SUM(t1.ActualCost) <> 0 )
GO
