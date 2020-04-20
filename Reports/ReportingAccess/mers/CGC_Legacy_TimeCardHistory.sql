/*
from [MCKTESTSQL04\VIEWPOINT].CV_CMS_SOURCE.dbo.JCTPST j

join Viewpoint.dbo.budxrefPhase p 
  on p.Company    = j.COMPANYNUMBER 
 and p.oldPhase   = ltrim(rtrim(j.JCDISTRIBTUION))
        
join Viewpoint.dbo.budxrefCostType c 
  on c.Company          = @PhaseGroup --(this should be 1 for all companies)
and c.CMSCostType      = isnull(p.newCosttype,j.COSTTYPE)

*/

DECLARE @Company	bCompany
DECLARE @Employee	bEmployee
DECLARE @EndDate SMALLDATETIME
SELECT @EndDate = '10/26/2014'

select
	CAST(left(prth.CHPRWE,4) AS int) as [Year]
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
--,	jcglpi.GLCo as JCGLCo
--,	jcglpi.Instance as JCGLDept
--,	jcglpi.Description as JCGLDeptDesc
,	case 
		when ltrim(rtrim(prth.CHJBNO)) is not null and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'Y' OR LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'X' ) then 'NonRevenue'
		when ltrim(rtrim(prth.CHJBNO)) is not null and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'Y' and LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'X' ) then 'Revenue'
		else 'Overhead'
	end as Classification
,	coalesce(sum(prth.CHRGHR+prth.CHOVHR+prth.CHOTHR),0) as ActualHours
,	(select sum(prth.CHRGHR+prth.CHOVHR+prth.CHOTHR) from mers.mvwPRPTCH where CHCONO=preh.PRCo and CHEENO=preh.Employee and CAST(left(CHPRWE,4) AS INT)=CAST(left(prth.CHPRWE,4) AS INT)) as TotalHours
,	null as AsOfPREndDate
from
	HQCO hqco join
	mers.mvwPRPTCH prth on
		hqco.HQCo=CASE prth.CHCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE prth.CHCONO END 
	and hqco.udTESTCo <> 'Y' LEFT OUTER JOIN
    budxrefPhase xref ON 
		prth.CHCONO = xref.Company
	and	LTRIM(RTRIM(prth.CHJCDI)) = xref.oldPhase LEFT OUTER JOIN
	PREHFullName preh on
		CASE prth.CHCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE prth.CHCONO END=preh.PRCo
	and prth.CHEENO=preh.Employee left outer join --select DISTINCT Company  FROM [dbo].[budxrefPhase]
	PRCM prcm on
		preh.PRCo=prcm.PRCo
	and preh.Craft=prcm.Craft LEFT OUTER JOIN
	PRCC prcc on
		preh.PRCo=prcc.PRCo
	and preh.Class=prcc.Class
	and prcc.Craft=prcm.Craft LEFT OUTER JOIN
	PRDP prdp on
		preh.PRCo=prdp.PRCo
	and preh.PRDept=prdp.PRDept /* LEFT OUTER JOIN
	JCJP jcjp on
		prth.JCCo=jcjp.JCCo
	and prth.Job=jcjp.Job 
	and prth.PhaseGroup=jcjp.PhaseGroup
	and prth.Phase=jcjp.Phase LEFT OUTER join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item  left outer join
	JCDM jcdm on
		jcdm.JCCo=jcci.JCCo
	and jcdm.Department=jcci.Department left outer join
	GLPI jcglpi on
		jcdm.GLCo=jcglpi.GLCo
	and jcglpi.PartNo=3
	and substring(jcdm.OpenRevAcct,10,4)=jcglpi.Instance */ left outer join
	GLPI prglpi on
		prdp.GLCo=prglpi.GLCo
	and prglpi.PartNo=3
	and substring(prdp.JCFixedRateGLAcct,10,4)=prglpi.Instance left outer join
	udEmpUtilization util on
		util.Co=prth.CHCONO
	and util.[Year]=CAST(left(prth.CHPRWE,4) AS INT)
	and util.Employee=prth.CHEENO
where
	--prth.Job is null
	CAST(LEFT(prth.CHPRWE,4) AS INT)=year(@EndDate)
and (prth.CHDTJR <= convert( int,@EndDate,112) or @EndDate is null)
and (preh.PRCo=@Company or @Company is null)
and (preh.Employee=@Employee or @Employee is null)
--and prth.Employee=68221
group by
	CAST(left(prth.CHPRWE,4) AS int) --as [Year]
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
--,	jcglpi.GLCo
--,	jcglpi.Instance --as JCGLDept
--,	jcglpi.Description --as JCGLDeptDesc
,	case 
		when ltrim(rtrim(prth.CHJBNO)) is not null and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'Y' OR LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'X' ) then 'NonRevenue'
		when ltrim(rtrim(prth.CHJBNO)) is not null and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'Y' and LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'X' ) then 'Revenue'
		else 'Overhead'
	end
            

SELECT
	hqco.HQCo
,	preh.Employee
,	preh.FullName
,	case 
		when ltrim(rtrim(prth.CHJBNO)) <> '' and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'Y' OR LEFT(ltrim(rtrim(prth.CHJBNO)),1) = 'X' ) then 'NonRevenue'
		when ltrim(rtrim(prth.CHJBNO)) <> '' and ( LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'Y' and LEFT(ltrim(rtrim(prth.CHJBNO)),1) <> 'X' ) then 'Revenue'
		else 'Overhead'
	end as Classification
,	jcjm.Description AS JobName
,	jcjm.Job
,	jcjm.udCGCJob
,	prth.CHJCDI
,	pxref.[Phase Code]
,	jcjp.Description
--,	jcci.Description AS ContractItemDesc
from 
	HQCO hqco join
	mers.mvwPRPTCH prth ON
		hqco.HQCo=CASE prth.CHCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE prth.CHCONO end
	AND hqco.udTESTCo <> 'Y' JOIN
	budxrefPhase xref ON 
		prth.CHCONO = xref.Company
	and	LTRIM(RTRIM(prth.CHJCDI)) = xref.oldPhase LEFT OUTER JOIN
	dbo.PREHFullName preh ON
		hqco.HQCo=preh.PRCo
	and prth.CHEENO=preh.Employee left outer join
	PRCM prcm on
		preh.PRCo=prcm.PRCo
	and preh.Craft=prcm.Craft LEFT OUTER JOIN
	PRCC prcc on
		preh.PRCo=prcc.PRCo
	and preh.Class=prcc.Class
	and prcc.Craft=prcm.Craft LEFT OUTER JOIN
	PRDP prdp on
		preh.PRCo=prdp.PRCo
	and preh.PRDept=prdp.PRDept LEFT OUTER JOIN
	JCJM jcjm ON
		jcjm.JCCo=CASE prth.CHCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE prth.CHCONO END
    AND jcjm.udCGCJob=CAST(prth.CHCONO AS VARCHAR(3)) + '-' + LTRIM(RTRIM(prth.CHJBNO)) LEFT OUTER JOIN
	budPayItemPhaseCodeMapping_new pxref ON
		prth.CHJCDI=pxref.PayItem LEFT OUTER JOIN
	JCJP jcjp ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job
	--AND jcjp.PhaseGroup=jcjm.JCCo
	AND LTRIM(RTRIM(jcjp.Phase))=LTRIM(RTRIM(pxref.[Phase Code])) /*LEFT OUTER JOIN
	JCCI jcci ON
		jcjp.JCCo=jcci.JCCo
	AND jcjp.Contract=jcci.Contract
	AND jcjp.Item=jcci.Item*/
WHERE
	CAST(LEFT(CHPRWE,4) AS INT)=YEAR(GETDATE())

--SELECT TOP 10 * FROM mers.mvwPRPTCH 

--SELECT TOP 10 * FROM JCJP

--SELECT * FROM budPayItemPhaseCodeMapping_new