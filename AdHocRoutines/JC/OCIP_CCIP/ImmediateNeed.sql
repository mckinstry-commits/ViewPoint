SELECT pvt.*
from
(
SELECT 
	jcjm.JCCo
,	jcjm.Job
,	jcjm.Description
,	jcjm.InsTemplate
,	jccd.PRCo
,	jccd.Employee
,	preh.FullName
,	jccd.Craft
,	prcm.Description AS CraftDesc
,	jccd.Class
,	prcc.Description AS ClassDesc
--,	jccd.ActualDate
,	jccd.PostedDate
,	CASE jccd.EarnType
		WHEN 5 THEN 'StraightTimeHours'
		WHEN 6 THEN 'OvertimeHours'
		else 'DoubletimeHours'
	END AS EarnType
,	jccd.ActualHours
,	jccd.ActualCost
FROM 
	JCJM jcjm JOIN
	JCCD jccd ON
		jcjm.JCCo=jccd.JCCo
	AND jcjm.Job=jccd.Job JOIN
	PREHName preh ON
		jccd.PRCo=preh.PRCo
	AND jccd.Employee=preh.Employee JOIN
	PRCM prcm ON
		jccd.PRCo=prcm.PRCo
	AND jccd.Craft=prcm.Craft JOIN
	PRCC prcc ON
		jccd.PRCo=prcc.PRCo
	AND	jccd.Class=prcc.Class
	AND jccd.Craft=prcc.Craft
WHERE
	jcjm.JCCo<100
AND jcjm.JCCo=1
and jcjm.Contract=' 15997-'
AND jccd.Mth='11/1/2014'
AND jcjm.JobStatus=1
AND jccd.EarnType IN (5,6,7)
) t1
PIVOT
(
	SUM(t1.ActualHours) FOR t1.EarnType in ([StraightTimeHours],[OvertimeHours],[DoubletimeHours])
) pvt

go

SELECT pvt.*
from
(
SELECT 
	jcjm.JCCo
,	jcjm.Job
,	jcjm.Description
,	jcjm.InsTemplate
,	jccd.PRCo
,	jccd.Employee
,	preh.FullName
,	jccd.Craft
,	prcm.Description AS CraftDesc
,	jccd.Class
,	prcc.Description AS ClassDesc
--,	jccd.ActualDate
,	jccd.PostedDate
,	CASE jccd.EarnType
		WHEN 5 THEN 'StraightTimeEarnings'
		WHEN 6 THEN 'OvertimeEarnings'
		else 'DoubletimeEarnings'
	END AS EarnType
,	jccd.ActualHours
,	jccd.ActualCost
FROM 
	JCJM jcjm JOIN
	JCCD jccd ON
		jcjm.JCCo=jccd.JCCo
	AND jcjm.Job=jccd.Job JOIN
	PREHName preh ON
		jccd.PRCo=preh.PRCo
	AND jccd.Employee=preh.Employee JOIN
	PRCM prcm ON
		jccd.PRCo=prcm.PRCo
	AND jccd.Craft=prcm.Craft JOIN
	PRCC prcc ON
		jccd.PRCo=prcc.PRCo
	AND	jccd.Class=prcc.Class
	AND jccd.Craft=prcc.Craft
WHERE
	jcjm.JCCo<100
AND jcjm.JCCo=1
and jcjm.Contract=' 15997-'
AND jccd.Mth='11/1/2014'
AND jcjm.JobStatus=1
AND jccd.EarnType IN (5,6,7)
) t1
PIVOT
(
	SUM(t1.ActualCost) FOR t1.EarnType in ([StraightTimeEarnings],[OvertimeEarnings],[DoubletimeEarnings])
) pvt
go


