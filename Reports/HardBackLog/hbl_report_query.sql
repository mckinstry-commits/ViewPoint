DECLARE @mth bMonth
DECLARE @co bCompany
DECLARE @tstCo bYN

SELECT @tstCo='Y', @mth='9/1/2014', @co=201

SELECT 
	COALESCE(jcip.Mth, jccp.Mth, @mth)
,	jccm.JCCo
,	jccm.Contract
,	jccm.Description
,	jcpr.DetMth
,	CASE
		WHEN COUNT(jcip.Item)=0 THEN 1
		ELSE SUM(jcpr.Amount)/COUNT(jcip.Item) 
	END AS ProjectedCost
,	COALESCE(SUM(jcip.ProjDollars),0) AS ProjectedRevenue
FROM 
	HQCO hqco JOIN 
	JCCM jccm ON
		hqco.HQCo=jccm.JCCo
	AND hqco.udTESTCo=@tstCo JOIN
	JCCI jcci ON
		jccm.JCCo=jcci.JCCo
	AND jccm.Contract=jcci.Contract JOIN
	JCJM jcjm ON 
		jccm.JCCo=jcjm.JCCo
	AND jccm.Contract=jcjm.Contract JOIN 
	JCJP jcjp ON
		jcjm.JCCo=jcjp.JCCo 
	AND jcjm.Job=jcjp.Job 
	AND jcjp.Item=jcci.Item JOIN	
	JCCH jcch ON
		jcch.JCCo=jcjp.JCCo
	AND jcch.Job=jcjp.Job
	AND jcch.PhaseGroup=jcjp.PhaseGroup
	AND jcch.Phase=jcjp.Phase LEFT OUTER JOIN
	JCCP jccp ON
		jcch.JCCo=jccp.JCCo 
	AND jcch.Job=jccp.Job 
	AND jcch.PhaseGroup=jccp.PhaseGroup 
	AND jcch.Phase=jccp.Phase 
	AND jcch.CostType=jccp.CostType LEFT OUTER JOIN
	JCPR jcpr ON
		jcch.JCCo=jcpr.JCCo
	AND jcch.Job=jcpr.Job
	AND jcch.PhaseGroup=jcpr.PhaseGroup
	AND jcch.Phase=jcpr.Phase
	AND jcch.CostType=jcpr.CostType 
	AND jccp.Mth=jcpr.Mth LEFT OUTER JOIN
	JCIP jcip ON
		jcip.JCCo=jcci.JCCo
	AND jcip.Contract=jcci.Contract
	AND jcip.Item=jcci.Item
	AND jcip.Mth=jcpr.Mth
WHERE
	jccm.JCCo=@co
AND COALESCE(jcip.Mth, jccp.Mth, @mth)=@mth
GROUP BY
	COALESCE(jcip.Mth, jccp.Mth, @mth)
,	jccm.JCCo
,	jccm.Contract
,	jccm.Description
,	jcpr.DetMth	
--,	COALESCE(jcip.ProjDollars,0)
--,	COALESCE(jcip.ProjDollars,jcci.ContractAmt)
ORDER BY 2,3,5


--SELECT * FROM JCPR WHERE Job in (select distinct Job from JCJM where Contract='080600-') and Mth='9/1/2014'
--SELECT sum(ProjDollars) FROM JCIP where Contract='080600-' and Mth='9/1/2014'





--SELECT 

--FROM 
--	JCCP jccp	
--WHERE 
--	Job='080600-004'
----SELECT 
----	*
----FROM 
----	dbo.JCForecastTotalsCost	

----SELECT 
----	*
----FROM 
----	dbo.JCForecastTotalsRev	
	
----SELECT 
----	*
----FROM 
----	dbo.JCForecastMonth



