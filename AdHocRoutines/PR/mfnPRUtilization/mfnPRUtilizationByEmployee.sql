--select * from mvwPRTH
--select * from PREC
use Viewpoint
go

--select sum(HoursAllocated) from [SESQL08].McK_HRDB.dbo.[EmployeeTimeOff] where EmployeeID=68221 and Year=2016

drop function [mers].[mfnGetEmployeePTOAllocation]
go

CREATE FUNCTION mers.mfnGetEmployeePTOAllocation
(
	@Employee	bEmployee
,	@Year		int
)
RETURNS decimal(10,2)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @retVal decimal(10,2)

	-- Add the T-SQL statements to compute the return value here
	select @retVal=sum(HoursAllocated) from [SESQL08].McK_HRDB.dbo.[EmployeeTimeOff] where EmployeeID=@Employee and Year=@Year

	select @retVal=coalesce(@retVal,0)


	-- Return the result of the function
	RETURN @retVal

END
GO

drop function [mers].[mfnPRUtilizationByEmployee]
go

create function [mers].[mfnPRUtilizationByEmployee]
(
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
,	@GLDept		varchar(20) = null
,	@PREndDate	datetime = null
)
returns table AS
/******************************************************************************************
* [mckPRUtlization]                                                                        *
*                                                                                         *
* Purpose: for SSRS PR utlization report by Employee with PRGLDept ,JCGLDEPT								  *
*                                                                                         *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================               *
* 12/11/20114   Arun Thomas       To be used for adhoc reporting                                                                              *
*                                                                                         *
*******************************************************************************************/
return
--BEGIN
--if @EndDate is null
--		select @EndDate=getdate()

select
		Year	
	,	PRCo	
	,	Employee	
	,	EmployeeName	
	,	PRGroup
	,	Craft	
	,	CraftDesc
	,	Class	
	,	ClassDesc
	,	PRGLCo	
	,	PRGLDept	
	,	PRGLDeptDesc	

	,	JCGLCo
	,	coalesce(JCGLDept,PRGLDept ) as JCGLDept
	,	coalesce(JCGLDeptDesc,PRGLDeptDesc + ' *PR*')	as JCGLDeptDesc
	,	PRPeriod as PRPeriod

	,	UtilizationGoal as JCUtilizationGoal

	,	coalesce(sum(Overhead),0) as OverheadHours		
	,	coalesce(sum(NonRevenue),0) as NonRevenueJobHours
	,	coalesce(sum(PTO),0) AS NonJobPTOHours
	,	coalesce(sum(Overhead),0) + coalesce(sum(NonRevenue),0) + coalesce(sum(PTO),0) as TotalOverheadHours

	,	coalesce(sum(Revenue),0) as RevenueJobHours	
	,	coalesce(sum(JobPTO),0) AS JobPTOHours
	,	coalesce(sum(Revenue),0) + coalesce(sum(JobPTO),0) as TotalJobHours

	,	coalesce(sum(Revenue),0) + coalesce(sum(NonRevenue),0) + coalesce(sum(JobPTO),0) as TotalUtilizationHours

	,	coalesce(sum(Overhead),0) + coalesce(sum(NonRevenue),0) + coalesce(sum(PTO),0) + coalesce(sum(Revenue),0) + coalesce(sum(JobPTO),0) as TotalHours

	
	from
	(
		select
			year(prth.PREndDate) as [Year]
		,	preh.PRCo
		,	preh.Employee
		,	preh.FullName as EmployeeName
		,	preh.PRGroup
		,	preh.Craft
		,	prcm.Description as CraftDesc
		,	preh.Class
		,	prcc.Description as ClassDesc
		,	prglpi.GLCo as PRGLCo
		,	prglpi.Instance as PRGLDept
		,	prglpi.Description as PRGLDeptDesc
		,	coalesce(case month(prth.PREndDate)
				when 1 then max(util.Jan)
				when 2 then max(util.Feb)
				when 3 then max(util.Mar)
				when 4 then max(util.Apr)
				when 5 then max(util.May)
				when 6 then max(util.Jun)
				when 7 then max(util.Jul)
				when 8 then max(util.Aug)
				when 9 then max(util.Sep)
				when 10 then max(util.Oct)
				when 11 then max(util.Nov)
				when 12 then max(util.Dec)
				else coalesce(sum((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),0)
			end,0) as UtilizationGoal
		--,	coalesce(max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),1) as UtilizationGoal
		,	jcglpi.GLCo as JCGLCo
		,	jcglpi.Instance as JCGLDept
		,	jcglpi.Description as JCGLDeptDesc
		,	case 
				when prth.Job is not null and jcci.udRevType='N' then 'NonRevenue'
				when prth.Job is not null and jcci.udRevType='' then 'NonRevenue'
				when prth.Job is not null and jcci.udRevType is null then 'NonRevenue'
				when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) and prth.EarnCode not in (5,6,7,8,9,10,11,12,13,14) then 'Revenue'
				when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then 'JobPTO'
				when prth.Job is null and prth.SMWorkOrder is not null then 'Revenue'
				when prth.Job is null and prth.SMWorkOrder is null and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then 'PTO'				
				when prth.Job is null and prth.SMWorkOrder is null and prth.EarnCode not in (5,6,7,8,9,10,11,12,13,14) then 'Overhead'		
				else 'Overhead'
			end as Classification
		,	coalesce(sum(prth.Hours),0) as ActualHours		
		,	(select sum(Hours) from mvwPRTH where PRCo=preh.PRCo and Employee=preh.Employee and PREndDate=prth.PREndDate ) as TotalHours		
		,	prth.PREndDate as PRPeriod
		--,	(select sum(Hours) from mvwPRTH where PRCo=preh.PRCo and Employee=preh.Employee and PREndDate=prth.PREndDate ) as GrandTotalHours
		--,	prth.EarnCode
		--,	case  
		--		when prth.Job is not null and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then coalesce(sum(prth.Hours),0)
		--		else 0
		--	end as JobPTOHours
		--,	case  
		--		when prth.Job is null and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then coalesce(sum(prth.Hours),0)
		--		else 0
		--	end as PTOHours
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
		and prth.EarnCode between 1 and 14
		and prth.Hours <> 0
		and (prth.PostDate <= @EndDate or @EndDate is null)
		and (preh.PRCo=@Company or @Company is null)
		and (prth.Employee=@Employee or @Employee is null)
		and (prth.PREndDate = @PREndDate or @PREndDate is null)
		and (ltrim(rtrim(prglpi.Instance))=@GLDept or @GLDept is null)
		--and prth.Employee=68221
		group by
			year(prth.PREndDate) --as [Year]
		,	preh.PRCo
		,	preh.Employee
		,	preh.PRGroup
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
				when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) and prth.EarnCode not in (5,6,7,8,9,10,11,12,13,14) then 'Revenue'
				when prth.Job is not null and ( jcci.udRevType <> 'N' and jcci.udRevType <> '' and jcci.udRevType is not null ) and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then 'JobPTO'
				when prth.Job is null and prth.SMWorkOrder is not null then 'Revenue'
				when prth.Job is null and prth.SMWorkOrder is null and prth.EarnCode in (5,6,7,8,9,10,11,12,13,14) then 'PTO'				
				when prth.Job is null and prth.SMWorkOrder is null and prth.EarnCode not in (5,6,7,8,9,10,11,12,13,14) then 'Overhead'		
				else 'Overhead'
			end
		,	prth.PREndDate
	) utilds
	PIVOT 
	(
		sum(ActualHours) FOR Classification in ([Overhead],[Revenue],[NonRevenue],[JobPTO],[PTO],[XXX])
	) pvt
	group by
		Year	
	,	PRCo	
	,	Employee	
	,	EmployeeName	
	,	PRGroup
	,	Craft	
	,	CraftDesc
	,	Class	
	,	ClassDesc
	,	PRGLCo	
	,	PRGLDept	
	,	PRGLDeptDesc	
	,	UtilizationGoal	
	,	JCGLCo	
	,	PRPeriod
	,	JCGLDept	
	,	JCGLDeptDesc
	,	TotalHours	
	--,	GrandTotalHours
	--order by
	--	[Year]
	--,	PRCo
	--,	Employee
	--,	PRPeriod
	--,	EarnCode
	--,	JobPTOHours
	--,	PTOHours
	
go

--BY Pay Period
drop function [mers].[mfnPRUtilizationByPayPeriod]
go


create function [mers].[mfnPRUtilizationByPayPeriod]
(
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
,	@GLDept		varchar(20) = null
,	@PREndDate	datetime = null
)
returns table AS return
select 
	Year	
,	PRCo	
,	Employee	
,	EmployeeName	
,	PRGroup
,	PRGLDept
,	PRGLDeptDesc
,	avg(JCUtilizationGoal) as JCUtilizationGoal
--,	JCUtilizationGoal
--,	mers.mfnGetEmployeePTOAllocation(Employee,Year)/52 as ProratedPTOAllocation
,	convert( varchar(10), PRPeriod, 120) as PRPeriod
,	sum(TotalHours) as TotalHours
,	sum(OverheadHours) as OverheadHours
,	sum(NonRevenueJobHours) as NonRevenueJobHours
,	sum(NonJobPTOHours) as NonJobPTOHours
,	sum(TotalOverheadHours) as TotalOverheadHours
,	case when sum(TotalHours) = 0 then 0 else sum(TotalOverheadHours) / sum(TotalHours) end as OverheadPct
,	sum(RevenueJobHours) as RevenueJobHours
,	sum(JobPTOHours) as JobPTOHours
,	sum(TotalJobHours) as TotalJobHours
,	case when sum(TotalHours) = 0 then 0 else sum(RevenueJobHours) / sum(TotalHours) end as JobCostPct
,	sum(TotalUtilizationHours) as TotalUtilizationHours
,	case when sum(TotalHours) = 0 then 0 else sum(TotalUtilizationHours) / sum(TotalHours) end as JCUtilizationPct
,	(avg(JCUtilizationGoal) - case when sum(TotalHours) = 0 then 0 else (sum(RevenueJobHours) / sum(TotalHours)) end ) * -1 as JobCostPctDelta
,	(avg(JCUtilizationGoal) - case when sum(TotalHours) = 0 then 0 else ( sum(TotalUtilizationHours) / sum(TotalHours))  end ) * -1  as JCUtilizationPctDelta
from 
	[mers].[mfnPRUtilizationByEmployee](@Company,@EndDate,@Employee,@GLDept,@PREndDate )
group by
	Year	
,	PRCo	
,	Employee	
,	EmployeeName	
,	PRGroup
,	PRGLDept
,	PRGLDeptDesc
--,	UtilizationGoal	
--,	JCUtilizationGoal
,	PRPeriod	
--,	TotalHours 
--order by
--	[Year]
--,	PRCo
--,	Employee
--,	PRPeriod
go

--By Month

drop function [mers].[mfnPRUtilizationByMonth]
go

create function [mers].[mfnPRUtilizationByMonth]
(
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
,	@GLDept		varchar(20) = null
,	@PREndDate	datetime = null
)
returns table AS return
select 
	Year	
,	PRCo	
,	Employee	
,	EmployeeName	
,	PRGroup
,	PRGLDept
,	PRGLDeptDesc
--,	UtilizationGoal	
,	avg(JCUtilizationGoal) as JCUtilizationGoal
--,	JCUtilizationGoal
--,	mers.mfnGetEmployeePTOAllocation(Employee,Year)/12 as ProratedPTOAllocation
,	cast(cast(year(PRPeriod) as varchar(4)) + '-' + cast(month(PRPeriod) as varchar(2)) as varchar(10)) as PRPeriod
,	sum(TotalHours) as TotalHours
,	sum(OverheadHours) as OverheadHours
,	sum(NonRevenueJobHours) as NonRevenueJobHours
,	sum(NonJobPTOHours) as NonJobPTOHours
,	sum(TotalOverheadHours) as TotalOverheadHours
,	case when sum(TotalHours) = 0 then 0 else sum(TotalOverheadHours) / sum(TotalHours) end as OverheadPct
,	sum(RevenueJobHours) as RevenueJobHours
,	sum(JobPTOHours) as JobPTOHours
,	sum(TotalJobHours) as TotalJobHours
,	case when sum(TotalHours) = 0 then 0 else sum(RevenueJobHours) / sum(TotalHours) end as JobCostPct
,	sum(TotalUtilizationHours) as TotalUtilizationHours
,	case when sum(TotalHours) = 0 then 0 else sum(TotalUtilizationHours) / sum(TotalHours) end as JCUtilizationPct
,	(avg(JCUtilizationGoal) - case when sum(TotalHours) = 0 then 0 else (sum(RevenueJobHours) / sum(TotalHours)) end ) * -1 as JobCostPctDelta
,	(avg(JCUtilizationGoal) - case when sum(TotalHours) = 0 then 0 else ( sum(TotalUtilizationHours) / sum(TotalHours))  end ) * -1  as JCUtilizationPctDelta
from 
	[mers].[mfnPRUtilizationByEmployee](@Company,@EndDate,@Employee,@GLDept,@PREndDate )
group by
	Year	
,	PRCo	
,	Employee	
,	EmployeeName	
,	PRGroup
,	PRGLDept
,	PRGLDeptDesc
--,	UtilizationGoal	
--,	JCUtilizationGoal
,	cast(year(PRPeriod) as varchar(4)) + '-' + cast(month(PRPeriod) as varchar(2))	
--order by
--	[Year]
--,	PRCo
--,	Employee
--,	cast(year(PRPeriod) as varchar(4)) + '-' + cast(month(PRPeriod) as varchar(2))	
go

--By Year

drop function [mers].[mfnPRUtilizationByYear]
go

create function [mers].[mfnPRUtilizationByYear]
(
  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
,	@GLDept		varchar(20) = null
,	@PREndDate	datetime = null
)
returns table AS return
select 
	ua.Year	
,	ua.PRCo	
,	ua.Employee	
,	ua.EmployeeName
,	ua.PRGroup	
,	ua.PRGLDept
,	ua.PRGLDeptDesc
--,	UtilizationGoal	
--,	avg(ua.JCUtilizationGoal) as JCUtilizationGoal
--,	coalesce(sum((ug.Jan+ug.Feb+ug.Mar+ug.Apr+ug.May+ug.Jun+ug.Jul+ug.Aug+ug.Sep+ug.Oct+ug.Nov+ug.Dec)/12),0) as JCUtilizationGoal
,	coalesce(max(ug.AnnualPct),0) as JCUtilizationGoal
--,	JCUtilizationGoal
--,	mers.mfnGetEmployeePTOAllocation(Employee,Year) as PTOAllocation
,	cast(ua.Year as varchar(10)) as PRPeriod
,	sum(ua.TotalHours) as TotalHours
,	sum(ua.OverheadHours) as OverheadHours
,	sum(ua.NonRevenueJobHours) as NonRevenueJobHours
,	sum(ua.NonJobPTOHours) as NonJobPTOHours
,	sum(ua.TotalOverheadHours) as TotalOverheadHours
,	case when sum(ua.TotalHours) = 0 then 0 else sum(ua.TotalOverheadHours) / sum(ua.TotalHours) end as OverheadPct
,	sum(ua.RevenueJobHours) as RevenueJobHours
,	sum(ua.JobPTOHours) as JobPTOHours
,	sum(ua.TotalJobHours) as TotalJobHours
,	case when sum(ua.TotalHours) = 0 then 0 else sum(ua.RevenueJobHours) / sum(ua.TotalHours) end as JobCostPct
,	sum(ua.TotalUtilizationHours) as TotalUtilizationHours
,	case when sum(ua.TotalHours) = 0 then 0 else sum(ua.TotalUtilizationHours) / sum(ua.TotalHours) end as JCUtilizationPct
,	(coalesce(max(ug.AnnualPct),0) - case when sum(ua.TotalHours) = 0 then 0 else (sum(ua.RevenueJobHours) / sum(ua.TotalHours)) end ) * -1 as JobCostPctDelta
,	(coalesce(max(ug.AnnualPct),0) - case when sum(ua.TotalHours) = 0 then 0 else ( sum(ua.TotalUtilizationHours) / sum(ua.TotalHours))  end ) * -1  as JCUtilizationPctDelta
from 
	[mers].[mfnPRUtilizationByEmployee](@Company,@EndDate,@Employee,@GLDept,@PREndDate )  ua left outer join
	udEmpUtilization ug on
		ua.PRCo=ug.Co
	and	ua.Employee=ug.Employee
	and ua.Year=ug.Year
group by
	ua.Year	
,	ua.PRCo	
,	ua.Employee	
,	ua.EmployeeName
,	ua.PRGroup
,	ua.PRGLDept
,	ua.PRGLDeptDesc
--,	UtilizationGoal	
--,	JCUtilizationGoal
--order by
--	[Year]
--,	PRCo
--,	Employee
go


drop procedure [mers].[mspPRUtilization]
go

create procedure [mers].[mspPRUtilization]
(
	@AggLevl	char(1) = null -- null = detail, P = PayPeriod, M = Month, Y = Year
,  	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
,	@GLDept		varchar(20) = null
,	@PREndDate	datetime = null
)
as
begin
	IF @EndDate IS NULL 
		SELECT @EndDate=GETDATE()

	if @PREndDate is not null and @PREndDate > @EndDate
		select @EndDate=@PREndDate

	if @PREndDate is not null
		select @PREndDate = [dbo].[fnMcKWeekEnding](@PREndDate)

	if @AggLevl = 'P' 
		select * from  [mers].[mfnPRUtilizationByPayPeriod] (@Company,@EndDate,@Employee,@GLDept,@PREndDate )
	else if @AggLevl = 'M'
		select * from  [mers].[mfnPRUtilizationByMonth] (@Company,@EndDate,@Employee,@GLDept,@PREndDate )
	else if @AggLevl = 'Y'
		select * from  [mers].[mfnPRUtilizationByYear] (@Company,@EndDate,@Employee,@GLDept,@PREndDate )
	else 
		select * from  [mers].[mfnPRUtilizationByEmployee] (@Company,@EndDate,@Employee,@GLDept,@PREndDate )

end

go


declare @Company	bCompany 
declare	@EndDate	datetime 
declare	@Employee	bEmployee 
declare @GLDept		varchar(20) 
declare	@PREndDate	datetime 

set @Company	= null
set	@EndDate	= '12/31/2016' 
set	@Employee	= null --78431 
set @GLDept		= null 
set	@PREndDate	= null 

--select * from  [mers].[mfnPRUtilizationByPayPeriod] (@Company,@EndDate,@Employee,@GLDept,@PREndDate ) where PRGroup = 1 and (JobCostPctDelta <> 0 or JCUtilizationPctDelta <> 0)

--exec [mers].[mspPRUtilization] 'P',@Company,@EndDate,@Employee,@GLDept,@PREndDate
--exec [mers].[mspPRUtilization] 'M',@Company,@EndDate,@Employee,@GLDept,@PREndDate
exec [mers].[mspPRUtilization] 'Y',@Company,@EndDate,@Employee,@GLDept,@PREndDate

--exec [mers].[mspPRUtilization] null,@Company,@EndDate,@Employee,@GLDept,@PREndDate

----FULL DETAIL
--select * from [mers].[mfnPRUtilizationByEmployee] (@Company,@EndDate,@Employee,@GLDept,@PREndDate ) order by [Year],PRCo,Employee,PRPeriod
--BY PAY PERIOD
--select * from [mers].[mfnPRUtilizationByPayPeriod] (@Company,@EndDate,@Employee,@GLDept,@PREndDate ) --order by [Year],PRCo,Employee,PRPeriod
----BY MONTH
--union
--select * from [mers].[mfnPRUtilizationByMonth] (@Company,@EndDate,@Employee,@GLDept,@PREndDate ) --order by [Year],PRCo,Employee,PRMonth
----BY YEAR
--union
--select * from [mers].[mfnPRUtilizationByYear] (@Company,@EndDate,@Employee,@GLDept,@PREndDate ) --order by [Year],PRCo,Employee
--order by [Year],PRCo,Employee,PRPeriod


--select * from PRTH where PREndDate='1/1/2015' and Employee=61660 and Hours=2.5