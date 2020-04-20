/*
2016.02.10 - LWO - Convert udEmpUtilization to have percentages as JCUtilization instead of OHUtilization

Update all percentage entries to be 1-current value.
*/


use Viewpoint
go

ALTER PROCEDURE [dbo].[mckPRUtilByEmployee](
    @Company bCompany
   ,@EndDate bDate = null
)
AS
/*******************************************************************************************
* [mckPRUtlization]                                                                        *
*                                                                                          *
* Purpose: for SSRS PR utlization report by Employee/Dept								   *
*                                                                                          *
*                                                                                          *
* Date			By			Comment                                                        *
* ==========	========	===================================================            *
* 2016.02.10    LWO         Altered to accomodate inverted percentages in udEmpUtilization *
*                                                                                          *
********************************************************************************************/
BEGIN

SELECT * 

FROM
(
SELECT 
	(CONVERT(VARCHAR(3),emp.PRCo) + ' - ' + co.Name) as Company, 
	--(emp.PRDept + ' - ' + dept.Description) as Department,
	emp.PRDept as Department,
	emp.Employee, 
	emp.FullName, 
	(emp.Class + ' - ' + ISNULL(cc.Description, 'No Class')) as EmpClass,
	oh.Hours as Overhead,
	d.ActualHours as ActualHours,
	ISNULL(YEAR(d.ActualDate), YEAR(oh.PREndDate)) as [Year],
	--isnull(eu.AnnualPct,1) as AnnualPct,
	/* 2016.02.10 - LWO - Adjustment to accomoate inverted values. */
	isnull(1-eu.AnnualPct,0) as AnnualPct,
	(CASE 
	WHEN c.udRevType = 'N'  THEN 'Non-Revenue'
	WHEN c.udRevType IS NULL  THEN 'Non-Revenue'
	ELSE 'Revenue'
	END) as RevenueType

FROM mvwPRTH  oh 
--(select PRCo, Employee, PREndDate, SUM(Hours) as Overhead from mvwPRTH 
--					where Job is null and PREndDate <= '11/18/2014' and YEAR(PREndDate) = YEAR('11/18/2014')
--					group by PRCo,Employee, PREndDate) as oh
		LEFT JOIN dbo.PREHFullName emp on oh.Employee = emp.Employee and oh.PRCo = emp.PRCo 
		LEFT JOIN dbo.JCCD d ON emp.Employee = d.Employee AND emp.PRCo = d.PRCo
		LEFT JOIN dbo.JCJP j on 
								d.JCCo = j.JCCo and d.Job = j.Job and d.Phase = j.Phase and d.PhaseGroup = j.PhaseGroup
								and d.CostType =1 and d.Source NOT IN ( 'JC CostAdj', 'JC OrigEst') and d.JCTransType ='PR'
								and YEAR(d.ActualDate) = YEAR(@EndDate) and d.ActualDate <= @EndDate
		LEFT JOIN dbo.JCCI c on j.JCCo = c.JCCo and j.Contract = c.Contract and  j.Item = c.Item 		
		LEFT JOIN dbo.HQCO co ON emp.PRCo = co.HQCo
		LEFT JOIN PRCC cc on emp.PRCo = cc.PRCo and emp.Craft = cc.Craft and emp.Class = cc.Class  
		LEFT JOIN udEmpUtilization eu on d.PRCo  = eu.Co and d.Employee = eu.Employee  and eu.Year = YEAR(@EndDate)
		
WHERE 
		emp.PRCo = @Company
		AND YEAR(oh.PREndDate) = YEAR(@EndDate)
		AND oh.PREndDate<= @EndDate
--GROUP BY 
--		CONVERT(VARCHAR(3),d.PRCo) + ' - ' + co.Name, 
--		--(emp.PRDept + ' - ' + dept.Description),
--		emp.PRDept,
--		d.Employee, 
--		(emp.Class + ' - ' + cc.Description),
--		emp.FullName, 
--		YEAR(d.ActualDate),
--		(CASE 
--		WHEN c.udRevType = 'N'  THEN 'Non-Revenue'
--		WHEN c.udRevType IS NULL  THEN 'Non-Revenue'
--		ELSE 'Revenue'
--		END)

) a 
PIVOT 
	(
	sum(ActualHours) FOR RevenueType in ([Revenue],[Non-Revenue])
	) pvt
ORDER BY Company,Department,Employee
END



GO


ALTER PROCEDURE [dbo].[mckPRUtilizationByCo](
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
)
AS
/******************************************************************************************
* [mckPRUtlization]                                                                        *
*                                                                                         *
* Purpose: for SSRS PR utlization report by Employee with PRGLDept ,JCGLDEPT								  *
*                                                                                         *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================               *
* 12/11/20114   Arun Thomas       To be used for adhoc reporting                          *
* 2016.02.10    LWO         Altered to accomodate inverted percentages in udEmpUtilization *
*                                                                                         *
*******************************************************************************************/
BEGIN
if @EndDate is null
		select @EndDate=getdate()

select
		Year	
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
	,	coalesce(JCGLDept,PRGLDept ) as JCGLDept
	,	coalesce(JCGLDeptDesc,PRGLDeptDesc + ' *PR*')	as JCGLDeptDesc
	,	max(AsOfPREndDate) as AsOfPREndDate
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
		--,	coalesce(max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),1) as UtilizationGoal
		,	coalesce(1-max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),0) as UtilizationGoal
		,	isnull(jcglpi.GLCo,prglpi.GLCo) as JCGLCo
		,	isnull(jcglpi.Instance,prglpi.Instance)  as JCGLDept
		,	isnull (jcglpi.Description,prglpi.Description)  as JCGLDeptDesc
		,	case 
				when prth.Job is not null and jcci.udRevType='N' then 'NonRevenue'
				when prth.Job is not null and jcci.udRevType='' then 'NonRevenue'
				when prth.Job is not null and jcci.udRevType is null then 'NonRevenue'
				when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) then 'Revenue'
				when prth.Job is null and prth.SMWorkOrder is not null then 'Revenue'
				else 'Overhead'
			end as Classification
		,	coalesce(sum(prth.Hours),0) as ActualHours
		,	(select sum(Hours) from mvwPRTH where PRCo=preh.PRCo and Employee=preh.Employee and year(PREndDate)=year(prth.PREndDate)
		 and PREndDate <= @EndDate ) as TotalHours
		,	max(prth.PREndDate) as AsOfPREndDate
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
			and jcjp.Item=jcci.Item  left outer join
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
			--prth.Job is null
			year(prth.PREndDate)=year(@EndDate)
		and (prth.PostDate <= @EndDate or @EndDate is null)
		and (preh.PRCo=@Company or @Company is null)
		--and (prth.Employee=@Employee or @Employee is null)
		group by
			year(prth.PREndDate) --as [Year]
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
				when prth.Job is null and prth.SMWorkOrder is not null then 'Revenue'
				else 'Overhead'
			end
	) utilds
	PIVOT 
	(
		sum(ActualHours) FOR Classification in ([Overhead],[Revenue],[NonRevenue])
	) pvt
	group by
		Year	
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
	,	TotalHours	
	order by
		[Year]
	,	PRCo
	,	Employee
END

GO

ALTER PROCEDURE [dbo].[mckPRUtilizationByEmployee](
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
)
AS
/******************************************************************************************
* [mckPRUtlization]                                                                        *
*                                                                                         *
* Purpose: for SSRS PR utlization report by Employee with PRGLDept ,JCGLDEPT				*
*                                                                                         *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================               *
* 12/11/20114   Arun Thomas       To be used for adhoc reporting                            *
* 2016.02.10    LWO         Altered to accomodate inverted percentages in udEmpUtilization *
*                                                                                         *
*******************************************************************************************/
BEGIN
if @EndDate is null
		select @EndDate=getdate()

select
		Year	
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
	,	coalesce(JCGLDept,PRGLDept ) as JCGLDept
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
		,	coalesce(1-max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),0) as UtilizationGoal
		--,	coalesce(max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),1) as UtilizationGoal
		,	jcglpi.GLCo as JCGLCo
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
		,	(select sum(Hours) from mvwPRTH where PRCo=preh.PRCo and Employee=preh.Employee and year(PREndDate)=year(prth.PREndDate)
		 and PREndDate <= @EndDate ) as TotalHours
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
			and jcjp.Item=jcci.Item  left outer join
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
			--prth.Job is null
			year(prth.PREndDate)=year(@EndDate)
		and (prth.PostDate <= @EndDate or @EndDate is null)
		and (preh.PRCo=@Company or @Company is null)
		and (prth.Employee=@Employee or @Employee is null)
		--and prth.Employee=68221
		group by
			year(prth.PREndDate) --as [Year]
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
			end
	) utilds
	PIVOT 
	(
		sum(ActualHours) FOR Classification in ([Overhead],[Revenue],[NonRevenue])
	) pvt
	group by
		Year	
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
	,	TotalHours	
	order by
		[Year]
	,	PRCo
	,	Employee
END

GO


--select * into udEmpUtilization_2016BU from udEmpUtilization

begin tran


update udEmpUtilization set
	Jan=1-Jan
,	Feb=1-Feb
,	Mar=1-Mar
,	Apr=1-Apr
,	May=1-May
,	Jun=1-Jun
,	Jul=1-Jul
,	Aug=1-Aug
,	Sep=1-Sep
,	Oct=1-Oct
,	Nov=1-Nov
,	Dec=1-Dec
,	Q1=1-Q1
,	Q2=1-Q2
,	Q3=1-Q3
,	Q4=1-Q4
,	AnnualPct=1-AnnualPct 
--where Employee<>68221

commit tran


--Set Quartly and Annual Percentages
begin tran
update udEmpUtilization set
	Q1=(Jan+Feb+Mar)/3
,	Q2=(Apr+May+Jun)/3
,	Q3=(Jul+Aug+Sep)/3
,	Q4=(Oct+Nov+Dec)/3
,	AnnualPct=(Jan+Feb+Mar+Apr+May+Jun+Jul+Aug+Sep+Oct+Nov+Dec)/12

commit tran
--select * from udEmpUtilization where Employee=68221 order by Employee, [Year] 