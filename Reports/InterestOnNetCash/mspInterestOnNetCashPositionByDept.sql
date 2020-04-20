
--sp_helptext brvJCWIPCashFlow

use Viewpoint 
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspInterestOnNetCashPositionByDept' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE dbo.mspInterestOnNetCashPositionByDept'
	DROP PROCEDURE dbo.mspInterestOnNetCashPositionByDept
end
go

print 'CREATE PROCEDURE dbo.mspInterestOnNetCashPositionByDept'
go

CREATE PROCEDURE dbo.mspInterestOnNetCashPositionByDept(
	@JCCo bCompany = null
,	@Contract bContract = null
,	@Month bMonth = null
)
as
BEGIN
	set nocount on
	SET ANSI_WARNINGS OFF

	if @Month is null select @Month = cast(MONTH(getdate()) as varchar(2)) + '/1/' + cast(YEAR(getdate()) as varchar(4))
	if day(@Month) <> 1 select @Month = cast(MONTH(@Month) as varchar(2)) + '/1/' + cast(YEAR(@Month) as varchar(4))
	

	declare @c_rate	bRate
	declare @d_rate	bRate
	declare @c_asof	bDate
	declare @d_asof	bDate

	select @c_rate = t1.Rate, @c_asof=t1.EffectiveDate from (select top 1 Rate, EffectiveDate from udCompanyRates where RateType='NCPC' and EffectiveDate <= @Month order by EffectiveDate desc) t1
	select @d_rate = t1.Rate, @d_asof=t1.EffectiveDate from (select top 1 Rate, EffectiveDate from udCompanyRates where RateType='NCPD' and EffectiveDate <= @Month order by EffectiveDate desc) t1

	create table #Revenue
	(
		JCCo			tinyint			null
	,	Contract		varchar(10)		null
	,	ContractDesc	varchar(60)		null
	--,	Item			varchar(16)		null
	--,	ContractItemDesc	varchar(60)		null
	,	GLDepartment	char(20)		null
	,	GLDepartmentName	varchar(60)		null
	,	POCName			varchar(60)		null
	,	ThroughMonth	smalldatetime	not null
	,	ContractAmount	numeric(20,2)	not null
	,	BilledAmt		numeric(20,2)	not null
	,	ReceivedAmt		numeric(20,2)	not null
	,	CurrentRetainAmt numeric(20,2)	not null
	,	ProjectDelivery		varchar(10)	null
	)


	--REVENUE
	insert #Revenue
	select 
		jcci.JCCo
	,	jcci.Contract
	,	jccm.Description as ContractDesc
	--,	jcci.Item
	--,	jcci.Description as ContractItemDesc
	,	coalesce(glpi.Instance,'0000                ') as GLDepartment
	,	coalesce(glpi.Description,'Corporate') as GLDepartmentName
	,	jcmp.Name as POC
	,	@Month as Mth
	,	sum(coalesce(jcip.ContractAmt,0)) as ContractAmt
	,	sum(coalesce(jcip.BilledAmt,0)) as BilledAmt
	,	sum(coalesce(jcip.ReceivedAmt,0)) as ReceivedAmt
	,	sum(coalesce(jcip.CurrentRetainAmt,0)) as CurrentRetainAmt
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end as ProjectDelivery
	from
		JCCM jccm left join
		JCCI jcci on
			jccm.JCCo=jcci.JCCo
		and jccm.Contract=jcci.Contract left join
		JCIP jcip on
			jcci.JCCo=jcip.JCCo
		and jcci.Contract=jcip.Contract
		and jcci.Item=jcip.Item
		and jcip.Mth <= @Month left join
		JCDM jcdm on
			jcci.JCCo=jcdm.JCCo
		and jcci.Department=jcdm.Department left join
		GLPI glpi on
			jcdm.GLCo=glpi.GLCo
		and glpi.PartNo=3
		and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left join
		JCMP jcmp on
			jccm.JCCo=jcmp.JCCo
		and jccm.udPOC=jcmp.ProjectMgr
	where
		(jccm.JCCo = @JCCo or @JCCo is null)
	and (jccm.Contract = @Contract or @Contract is null)
	and jccm.ContractStatus = 1
	and jccm.JCCo < 100
	--and jcci.udProjDelivery <> 'I'
	group by
		jcci.JCCo
	,	jcci.Contract
	--,	jcci.Item
	,	glpi.Instance
	,	jcmp.Name
	,	jccm.Description 
	--,	jcci.Description 
	,	glpi.Description 
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end 


	create table #Cost
	(
		JCCo			tinyint			null
	,	Contract		varchar(10)		null
	,	ContractDesc	varchar(60)		null
	--,	Item			varchar(16)		null
	--,	ContractItemDesc	varchar(60)		null
	,	GLDepartment	char(20)		null
	,	GLDepartmentName	varchar(60)		null
	,	POCName			varchar(60)		null
	,	ThroughMonth	smalldatetime	null
	,	ActualCost		numeric(20,2)	not null
	,	TotalCmtdCost	numeric(20,2)	not null
	,	CurrEstCost		numeric(20,2)	not null
	,	ProjectDelivery		varchar(10)	null
	)

	--COST
	-- Optional Pivot to show Cost Types by column.

	insert #Cost
	select 
		jcjp.JCCo
	--,	jcjm.Job
	,	jcjp.Contract
	,	jccm.Description as ContractDesc
	--,	jcjp.Item
	--,	jcci.Description as ContractItemDesc
	,	coalesce(glpi.Instance,'0000                ') as GLDepartment
	,	coalesce(glpi.Description,'Corporate') as GLDepartmentName
	,	jcmp.Name as POC
	,	@Month as Mth
	,	sum(coalesce(jccp.ActualCost,0)) as ActualCost
	,	sum(coalesce(jccp.TotalCmtdCost,0)) as TotalCmtdCost
	,	sum(coalesce(jccp.CurrEstCost,0)) as CurrEstCost
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end as ProjectDelivery
	from
		JCCM jccm left join
		JCJM jcjm on
			jccm.JCCo=jcjm.JCCo
		and jccm.Contract=jcjm.Contract left join
		JCJP jcjp on
			jcjm.JCCo=jcjp.JCCo
		and jcjm.Job=jcjp.Job left join
		JCCP jccp on
			jcjp.JCCo=jccp.JCCo
		and jcjp.Job=jccp.Job
		and jcjp.PhaseGroup=jccp.PhaseGroup
		and jcjp.Phase=jccp.Phase
		and jccp.Mth <= @Month inner join  -- Added
		JCCI jcci on
			jcjp.JCCo=jcci.JCCo
		and jcjp.Contract=jcci.Contract
		and jcjp.Item=jcci.Item left join
		JCDM jcdm on
			jcci.JCCo=jcdm.JCCo
		and jcci.Department=jcdm.Department left join
		GLPI glpi on
			jcdm.GLCo=glpi.GLCo
		and glpi.PartNo=3
		and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left join
		JCMP jcmp on
			jccm.JCCo=jcmp.JCCo
		and jccm.udPOC=jcmp.ProjectMgr
	where
		(jcjm.JCCo = @JCCo or @JCCo is null)
	and (jcjm.Contract = @Contract or @Contract is null)
	and jccm.ContractStatus = 1
	and jccm.JCCo < 100
	--and jcci.udProjDelivery <> 'I'
	group by 
		jcjp.JCCo
	--,	jcjm.Job
	,	jcjp.Contract
	--,	jcjp.Item
	--,	jcjm.Description
	--,	jcjp.Phase
	--,	jcjp.Description 
	,	jcmp.Name
	,	jccm.Description 
	--,	jcci.Description 
	,	glpi.Instance
	,	glpi.Description 
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end 

	create table #OpenAP
	(
		JCCo			tinyint			null
	,	Contract		varchar(10)		null
	,	ContractDesc	varchar(60)		null
	--,	Item			varchar(16)		null
	--,	ContractItemDesc	varchar(60)		null
	,	GLDepartment	char(20)		null
	,	GLDepartmentName	varchar(60)		null
	,	POCName			varchar(60)		null
	,	ThroughMonth	smalldatetime	not null
	,	APOpenAmt		numeric(20,2)	not null
	,	ProjectDelivery		varchar(10)	null
	)

	insert #OpenAP
	select
		jccm.JCCo
	,	jccm.Contract
	,	jccm.Description as ContractDesc
	--,	jcjp.Item
	--,	jcci.Description as ContractItemDesc
	,	coalesce(glpi.Instance,'0000                ') as GLDepartment
	,	coalesce(glpi.Description,'Corporate') as GLDepartmentName
	,	jcmp.Name as POC
	,	@Month as ThroughMonth
	,	coalesce( (Sum(aptd.Amount) - Sum(aptd.GSTtaxAmt)), 0) as APOpenAmt
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end as ProjectDelivery
	from
	JCCM jccm left join
	JCJM jcjm on
		jccm.JCCo=jcjm.JCCo
	and jccm.Contract=jcjm.Contract left join
	JCJP jcjp on
		jcjm.JCCo=jcjp.JCCo
	and jcjm.Job=jcjp.Job left join
	APTL aptl on
		aptl.JCCo=jcjp.JCCo 
	and aptl.Job=jcjp.Job
	and aptl.PhaseGroup=jcjp.PhaseGroup
	and aptl.Phase=jcjp.Phase 
	and aptl.Mth <= @Month join 
	APTD aptd on 
		aptd.APCo=aptl.APCo 
	and aptd.Mth=aptl.Mth 
	and aptd.APTrans=aptl.APTrans 
	and aptd.APLine=aptl.APLine
	and aptd.Status <= 2
	and aptd.Mth <= @Month  inner join  -- Added
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item left join
	JCDM jcdm on
		jcci.JCCo=jcdm.JCCo
	and jcci.Department=jcdm.Department left join
	GLPI glpi on
		jcdm.GLCo=glpi.GLCo
	and glpi.PartNo=3
	and glpi.Instance=substring(jcdm.OpenRevAcct,10,4) left join
	JCMP jcmp on
		jccm.JCCo=jcmp.JCCo
	and jccm.udPOC=jcmp.ProjectMgr
	where
		(jcjm.JCCo = @JCCo or @JCCo is null)
	and (jcjm.Contract = @Contract or @Contract is null)
	and jccm.ContractStatus = 1
	and jccm.JCCo < 100
	--and jcci.udProjDelivery<>'I'
	group by
		jccm.JCCo
	,	jccm.Contract
	--,	jcjp.Item
	,	jcmp.Name
	,	jccm.Description 
	--,	jcci.Description 
	,	glpi.Instance
	,	glpi.Description 
	,	case when coalesce(jcci.udProjDelivery,'X') ='I' then jcci.udProjDelivery else null end 


	set nocount off 

	select
		coalesce(r.JCCo,c.JCCo,a.JCCo) as JCCo		
	,	coalesce(r.Contract,c.Contract, a.Contract) as Contract	
	,	coalesce(r.ContractDesc,c.ContractDesc, a.ContractDesc) as ContractDesc
	--,	coalesce(r.Item,c.Item, a.Item) as Item		 
	--,	coalesce(r.ContractItemDesc,c.ContractItemDesc,a.ContractItemDesc,'Unknown') as ContractItemDesc
	,	coalesce(r.GLDepartment,c.GLDepartment, a.GLDepartment,'0000                ') as GLDepartment
	,	coalesce(r.GLDepartmentName,c.GLDepartmentName,a.GLDepartmentName,'Corporate') as GLDepartmentName
	,	coalesce(r.POCName,c.POCName,a.POCName,'Undefined') as POCName
	,	coalesce(r.ThroughMonth, c.ThroughMonth,a.ThroughMonth,@Month) as ThroughMonth
	,	coalesce(r.ContractAmount,0) as ContractAmount	
	,	coalesce(c.CurrEstCost,0) as EstimatedCost	
	,	coalesce(r.ContractAmount,0) - coalesce(c.CurrEstCost,0) as EstimatedGrossProfit
	,	coalesce(r.BilledAmt,0) as BillingsToDate
	,	coalesce(r.BilledAmt,0)-coalesce(r.ReceivedAmt,0) as ContractReceivablesRetainage
	--,	coalesce(r.CurrentRetainAmt,0) as CurrentRetainAmt
	,	coalesce(r.ReceivedAmt,0) as CashCollected		
	,	coalesce(c.ActualCost,0) as CostToDate		
	--,	coalesce(c.TotalCmtdCost,0) as TotalCmtdCost	
	,	coalesce(a.APOpenAmt,0) as AccountsPayable
	,	coalesce(c.ActualCost,0)-coalesce(a.APOpenAmt,0) as CashPaid
	--,	coalesce(a.APOpenAmt,0) as APOpenAmt
	,	coalesce(r.ReceivedAmt,0)-(coalesce(c.ActualCost,0)-coalesce(a.APOpenAmt,0)) as NetCashFlow
	,	case 
			when coalesce(r.ProjectDelivery,c.ProjectDelivery,a.ProjectDelivery) = 'I' then 0
			when 
				(coalesce(r.ReceivedAmt,0)-(coalesce(c.ActualCost,0)-coalesce(a.APOpenAmt,0))) < 0 
				then ((coalesce(r.ReceivedAmt,0)-(coalesce(c.ActualCost,0)-coalesce(a.APOpenAmt,0))) * (@d_rate/12)) --* -1
			else ((coalesce(r.ReceivedAmt,0)-(coalesce(c.ActualCost,0)-coalesce(a.APOpenAmt,0))) * (@c_rate/12)) --* -1
		end as InterestOnCashPosition
	,	case when coalesce(r.ProjectDelivery,c.ProjectDelivery,a.ProjectDelivery) = 'I' then 0 else @c_rate end as CreditRate
	--,	@c_rate as CreditRate
	,	@c_asof as CreditRateAsOf
	,	case when coalesce(r.ProjectDelivery,c.ProjectDelivery,a.ProjectDelivery) = 'I' then 0 else @d_rate end as DebitRate
	--,	@d_rate as DebitRate
	,	@d_asof as DebitRateAsOf
	,   coalesce(r.ProjectDelivery,c.ProjectDelivery,a.ProjectDelivery) as ProjectDelivery
	from
		#Revenue r full join
		#Cost c on
			r.JCCo=c.JCCo
		and r.Contract=c.Contract
		and r.GLDepartment=c.GLDepartment full join
		#OpenAP a on
			a.JCCo=coalesce(r.JCCo, c.JCCo)
		and a.Contract=coalesce(r.Contract,c.Contract)
		and a.GLDepartment=coalesce(r.GLDepartment,c.GLDepartment)
	where
		coalesce(r.JCCo,c.JCCo,a.JCCo) is not null
	order by
		coalesce(r.JCCo,c.JCCo) 
	,	coalesce(r.Contract,c.Contract) 
	--,	coalesce(r.Item,c.Item) 


	drop table #Revenue
	drop table #Cost
	drop table #OpenAP

END
GO

grant exec on dbo.mspInterestOnNetCashPositionByDept to Viewpoint
grant exec on dbo.mspInterestOnNetCashPositionByDept to public


declare @JCCo bCompany = null
declare @Contract bContract = null
declare @Month bMonth = null

set @JCCo = null
set @Contract = ' 10081-'
--set @Contract = ' 10009-'

--set @Contract = null
set @Month = '12/1/2015'


exec dbo.mspInterestOnNetCashPositionByDept @JCCo=@JCCo, @Contract=@Contract, @Month=@Month

