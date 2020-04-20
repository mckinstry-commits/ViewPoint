use Viewpoint
go

set nocount on
go


if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

IF EXISTS ( SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='mers' AND TABLE_NAME='PRPTCH' )
BEGIN
	PRINT 'DROP TABLE mers.PRPTCH'
	DROP TABLE mers.PRPTCH
END
go

PRINT 'create TABLE mers.PRPTCH'
go

SELECT 
	*
INTO
	mers.PRPTCH
from 
	CMS.S1017192.CMSFIL.PRPTCH
WHERE
	CHCONO IN (1,15,20,30,50,60)
AND LEFT(CHPRWE,4) = 2014
go

--Update mers.PRPTCH records to have corrected Companies, Classes, Types or generate view that translates these.
if exists ( select * from [INFORMATION_SCHEMA].[VIEWS] where TABLE_SCHEMA='mers' and TABLE_NAME='mvwPRPTCH')
begin
	print 'DROP VIEW mers.mvwPRPTCH'
	DROP VIEW mers.mvwPRPTCH
end
go

print 'CREATE VIEW mers.mvwPRPTCH'
go

CREATE VIEW mers.mvwPRPTCH 
AS

select * from mers.PRPTCH

GO


if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnUtilizationByEmployee')
begin
	print 'DROP FUNCTION mers.mfnUtilizationByEmployee'
	DROP FUNCTION mers.mfnUtilizationByEmployee
end
go

print 'CREATE FUNCTION mers.mfnUtilizationByEmployee'
go

CREATE FUNCTION mers.mfnUtilizationByEmployee 
(	
	-- Add the parameters for the function here
	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
)
RETURNS @retTable TABLE 
(
	Year					INT					null
,	PRCo					bCompany			null
,	Employee				bEmployee			null
,	EmployeeName			VARCHAR(85)			null
,	Craft					bCraft				null
,	CraftDesc				bDesc				null
,	Class					bClass				null
,	ClassDesc				bDesc				null
,	PRGLCo					bCompany			null
,	PRGLDept				VARCHAR(20)			null
,	PRGLDeptDesc			bDesc				null
,	UtilizationGoal			bPct				null
,	AsOfPREndDate			SMALLDATETIME		null
,	OverheadHours			bHrs				null default (0)
,	OverheadHoursPct		bPct				null default (0)
,	NonRevenueJobHours		bHrs				null default (0)
,	NonRevenueJobHoursPct	bPct				null default (0)
,	TotalOverheadHours		bHrs				null default (0)
,	TotalOverheadHoursPct	bPct				null default (0)
,	RevenueJobHours			bHrs				null default (0)
,	RevenueJobHoursPct		bPct				NULL default (0)
,	TotalHours				bHrs				null default (0)
)
AS
begin
	if @EndDate is null
		select @EndDate=getdate()

	-- Add the SELECT statement with parameter references here
	insert @retTable 
	( 
		Year					--INT					null
	,	PRCo					--bCompany			null
	,	Employee				--bEmployee			null
	,	EmployeeName			--VARCHAR(85)			null
	,	Craft					--bCraft				null
	,	CraftDesc				--bDesc				null
	,	Class					--bClass				null
	,	ClassDesc				--bDesc				null
	,	PRGLCo					--bCompany			null
	,	PRGLDept				--VARCHAR(20)			null
	,	PRGLDeptDesc			--bDesc				null
	,	UtilizationGoal			--bPct				null
	,	AsOfPREndDate			--SMALLDATETIME		null
	,	OverheadHours			--bHrs				null default (0)
	,	OverheadHoursPct		--bPct				null default (0)
	,	NonRevenueJobHours		--bHrs				null default (0)
	,	NonRevenueJobHoursPct	--bPct				null default (0)
	,	TotalOverheadHours		--bHrs				null default (0)
	,	TotalOverheadHoursPct	--bPct				null default (0)
	,	RevenueJobHours			--bHrs				null default (0)
	,	RevenueJobHoursPct		--bPct				NULL default (0)
	,	TotalHours				--bHrs				null default (0)
	)
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
	--,	JCGLCo
	--,	coalesce(JCGLDept,PRGLDept) as JCGLDept
	--,	coalesce(JCGLDeptDesc,PRGLDeptDesc + ' *PR*')	as JCGLDeptDesc
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
		,	coalesce(max((util.Jan+util.Feb+util.Mar+util.Apr+util.May+util.Jun+util.Jul+util.Aug+util.Sep+util.Oct+util.Nov+util.Dec)/12),1) as UtilizationGoal
		--,	jcglpi.GLCo as JCGLCo
		--,	jcglpi.Instance as JCGLDept
		--,	jcglpi.Description as JCGLDeptDesc
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
		--,	jcglpi.GLCo
		--,	jcglpi.Instance --as JCGLDept
		--,	jcglpi.Description --as JCGLDeptDesc
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
	--,	JCGLCo	
	--,	JCGLDept	
	--,	JCGLDeptDesc
	,	TotalHours	
	order by
		[Year]
	,	PRCo
	,	Employee
	RETURN 
end 
GO

--select * from mers.mfnUtilizationByEmployee(1,'11/23/2014')
--go


if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' and ROUTINE_NAME='mspUtilizationByEmployee')
begin
	print 'DROP PROCEDURE mers.mspUtilizationByEmployee'
	DROP PROCEDURE mers.mspUtilizationByEmployee
end
go

print 'CREATE PROCEDURE mers.mspUtilizationByEmployee'
go

CREATE PROCEDURE mers.mspUtilizationByEmployee
(	
	-- Add the parameters for the function here
	@Company	bCompany = null
,	@EndDate	datetime = NULL
,	@Employee	bEmployee = null
)
AS
BEGIN

	select * from mers.mfnUtilizationByEmployee(@Company,@EndDate,@Employee)

	--Return value is number of records 
	return @@rowcount
END
GO

declare @rcode int
exec @rcode = mers.mspUtilizationByEmployee @Company=1,@EndDate='11/30/2014'
print 'Proc Exec @rcode=' + cast(@rcode as varchar(10))
--exec @rcode = mers.mspUtilizationByEmployee @Company=1,@EndDate=null
--print 'Proc Exec @rcode=' + cast(@rcode as varchar(10))
--go

if exists ( select * from [INFORMATION_SCHEMA].[VIEWS] where TABLE_SCHEMA='mers' and TABLE_NAME='mvwUtilizationByEmployee')
begin
	print 'DROP VIEW mers.mvwUtilizationByEmployee'
	DROP VIEW mers.mvwUtilizationByEmployee
end
go

print 'CREATE VIEW mers.mvwUtilizationByEmployee'
go

CREATE VIEW mers.mvwUtilizationByEmployee 
AS

select * from mers.mfnUtilizationByEmployee(null,NULL,null)

GO

--select * from mers.mvwTestFunction 
--go





