
declare @EndDate SMALLDATETIME
DECLARE @Job bJob

SELECT @EndDate='12/7/2014', @Job=' 11071-'


select
	Year	
,	Month
,	PRCo	
,	Employee	
,	EmployeeName	
,	Job
,	JobName
,	Craft	
,	CraftDesc
,	Class	
,	ClassDesc
,	PRGLCo	
,	PRGLDept	
,	PRGLDeptDesc	
,	UtilizationGoal	
,	JCGLCo
,	coalesce(JCGLDept,PRGLDept) as JCGLDept
,	coalesce(JCGLDeptDesc,PRGLDeptDesc + ' *PR*')	as JCGLDeptDesc
,	min(AsOfPREndDate) as AsOfPREndDate
,	coalesce(sum(Overhead),0) as OverheadHours	
,	case coalesce(sum(TotalHours),0) when 0 then 0 else coalesce(sum(Overhead),0) / coalesce(TotalHours,0)  end as OverheadHoursPct
,	coalesce(sum(NonRevenue),0) as NonRevenueJobHours
,	case coalesce(sum(TotalHours),0) when 0 then 0 else coalesce(sum(NonRevenue),0) / coalesce(TotalHours,0)  end as NonRevenueJobHoursPct
,	coalesce(sum(Overhead),0) + coalesce(sum(NonRevenue),0) as TotalOverheadHours
,	case coalesce(sum(TotalHours),0) when 0 then 0 else (coalesce(sum(Overhead),0) + coalesce(sum(NonRevenue),0)) / coalesce(TotalHours,0)  end as TotalOverheadHoursPct
,	coalesce(sum(Revenue),0) as RevenueJobHours	
,	case coalesce(sum(TotalHours),0) when 0 then 0 else coalesce(sum(Revenue),0) / coalesce(TotalHours,0)  end as RevenueJobHoursPct
,	coalesce(TotalHours,0) as TotalHours
--,	coalesce(sum(Overhead),0) + coalesce(sum(Revenue),0) + coalesce(sum(NonRevenue),0) as TotalHours
from
(
	select
		year(prth.PREndDate) as [Year]
	,	Month(prth.PREndDate) as [Month]
	,	preh.PRCo
	,	preh.Employee
	,	preh.FullName as EmployeeName
	,	preh.Craft
	,	prcm.Description as CraftDesc
	,	preh.Class
	,	prcc.Description as ClassDesc
	,	prglpi.GLCo as PRGLCo
	,	prglpi.Instance as PRGLDept
	,	prglpi.Description as PRGLDeptDesc
	,	coalesce(max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),1) as UtilizationGoal
	,	jcglpi.GLCo as JCGLCo
	,	jcjm.Job 
	,	jcjm.Description AS JobName
	,	jcglpi.Instance as JCGLDept
	,	jcglpi.Description as JCGLDeptDesc
	,	case 
			when prth.Job is not null and jcci.udRevType='N' then 'NonRevenue'
			when prth.Job is not null and jcci.udRevType='' then 'NonRevenue'
			when prth.Job is not null and jcci.udRevType is null then 'NonRevenue'
			when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) then 'Revenue'
			else 'Overhead'
		end as Classification
	,	coalesce(sum(prth.Hours),0) as ActualHours
	,	(select sum(Hours) from mvwPRTH where PRCo=preh.PRCo and Employee=preh.Employee and year(PREndDate)=year(prth.PREndDate)) as TotalHours
	,	min(prth.PREndDate) as AsOfPREndDate
	from 
		HQCO hqco join
		mvwPRTH prth on
			hqco.HQCo=prth.PRCo 
		and hqco.udTESTCo <> 'Y' LEFT OUTER join
		PREHFullName preh on
			prth.PRCo=preh.PRCo
		and prth.Employee=preh.Employee left outer join
		PRCM prcm on
			prth.PRCo=prcm.PRCo
		and prth.Craft=prcm.Craft LEFT OUTER JOIN
		PRCC prcc on
			prth.PRCo=prcc.PRCo
		and prth.Class=prcc.Class
		and prcc.Craft=prcm.Craft LEFT OUTER JOIN
		PRDP prdp on
			preh.PRCo=prdp.PRCo
		and preh.PRDept=prdp.PRDept LEFT OUTER JOIN
		JCJP jcjp on
			prth.JCCo=jcjp.JCCo
		and prth.Job=jcjp.Job 
		and prth.PhaseGroup=jcjp.PhaseGroup
		and prth.Phase=jcjp.Phase LEFT OUTER join
		JCCI jcci on
			jcjp.JCCo=jcci.JCCo
		and jcjp.Contract=jcci.Contract
		and jcjp.Item=jcci.Item  left outer JOIN
        JCJM jcjm ON
			jcjp.JCCo=jcjm.JCCo
		AND jcjp.Job=jcjm.Job  left outer JOIN
		JCDM jcdm on
			jcdm.JCCo=jcci.JCCo
		and jcdm.Department=jcci.Department left outer join
		GLPI jcglpi on
			jcdm.GLCo=jcglpi.GLCo
		and jcglpi.PartNo=3
		and substring(jcdm.OpenRevAcct,10,4)=jcglpi.Instance left outer join
		GLPI prglpi on
			prdp.GLCo=prglpi.GLCo
		and prglpi.PartNo=3
		and substring(prdp.JCFixedRateGLAcct,10,4)=prglpi.Instance left outer join
		udEmpUtilization util on
			util.Co=prth.PRCo
		and util.[Year]=year(prth.PREndDate)
		and util.Employee=prth.Employee
	where
		 (prth.PREndDate <= @EndDate or @EndDate is null)
	AND jcjm.JobStatus=1 
	AND jcjm.InsTemplate=3
	AND jcjm.Contract=@Job
	--and prth.Employee=68221
	group by
		year(prth.PREndDate) --as [Year]
	,	month(prth.PREndDate) --as [Year]
	,	preh.PRCo
	,	preh.Employee
	,	preh.FullName
	,	preh.Craft
	,	prcm.Description
	,	preh.Class
	,	prcc.Description
	,	prglpi.GLCo
	,	prglpi.Instance --as PRGLDept
	,	prglpi.Description --as PRGLDeptDesc
	,	jcglpi.GLCo
	,	jcglpi.Instance --as JCGLDept
	,	jcglpi.Description --as JCGLDeptDesc
	,	case 
			when prth.Job is not null and jcci.udRevType='N' then 'NonRevenue'
			when prth.Job is not null and jcci.udRevType='' then 'NonRevenue'
			when prth.Job is not null and jcci.udRevType is null then 'NonRevenue'
			when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) then 'Revenue'
			else 'Overhead'
		END
	,	jcjm.Job 
	,	jcjm.Description
) utilds
PIVOT 
(
	sum(ActualHours) FOR Classification in ([Overhead],[Revenue],[NonRevenue])
) pvt
group by
	Year
,	Month	
,	PRCo	
,	Employee	
,	EmployeeName	
,	Craft	
,	CraftDesc
,	Class	
,	ClassDesc
,	PRGLCo	
,	PRGLDept	
,	PRGLDeptDesc	
,	UtilizationGoal	
,	JCGLCo	
,	JCGLDept	
,	JCGLDeptDesc
,	Job
,	JobName
,	TotalHours	
order by
	[Year]
,	PRCo
,	Employee

--WHERE InsTemplate=3 AND JCCo<100 AND JobStatus IN (1)