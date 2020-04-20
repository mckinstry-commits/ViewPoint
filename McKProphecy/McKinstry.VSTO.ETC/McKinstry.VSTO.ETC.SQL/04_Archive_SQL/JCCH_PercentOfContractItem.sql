

--select JCCo, Contract, count(Item) from JCCI group by JCCo, Contract having count(*)>1 order by 3 DESC

use Viewpoint
go

--Add as Viewpoint UD Fields to JC and PM Contract Items
/*
alter table bJCCI
add
	udPercentOfContract			bPct	not null default 0
,	udPercentOfContractBasis	char(1)	not null default 'P'
,	udPercentOfContractAsOf		bMonth	null 
go
sp_refreshview @viewname = 'JCCI'
*/

--Add as Viewpoint UD Fields to JC and PM JobPhases(JCJP) and JobPhase/CostType (JCCH)
/*
alter table bJCCH
add
	udPercentOfJob					bPct	not null default 0
,	udPercentOfJobBasis				char(1)	not null default 'P'
,	udPercentOfJobAsOf				bMonth	null
,	udPercentOfContractItem			bPct	not null default 0
,	udPercentOfContractItemBasis	char(1)	not null default 'P'
,	udPercentOfContractItemAsOf		bMonth	null
go
sp_refreshview @viewname = 'JCCH'

*/

--select * from DDFIc where Form='JCJPCostTypes'

update DDFIc set DisableInput='Y', ShowGrid='N' where Form='JCJPCostTypes' and ColumnName in 
(
'udPercentOfJob','udPercentOfJobBasis','udPercentOfJobAsOf',
'udPercentOfContractItem','udPercentOfContractItemBasis','udPercentOfContractItemAsOf'
)


if exists ( select 1 from sysobjects where type='P' and name='mspGenJCCHContractItemPercentage')
begin
	print 'drop procedure mspGenJCCHContractItemPercentage'
	drop procedure mspGenJCCHContractItemPercentage
end
go

print 'create procedure mspGenJCCHContractItemPercentage'
go

create procedure mspGenJCCHContractItemPercentage
(
	@JCCo			bCompany
,	@Job		bContract
,	@Month			bMonth
,	@ShowResults	tinyint	= 0
)
as
begin
	/*
	2016.04.14 - LWO - Created

	Utility procedure to update UD fields on JCCI


	*/
	set nocount on

	print cast(@JCCo as char(5)) + cast(@Job as char(15)) + convert(varchar(10), @Month, 101)

	declare @sum_of_job_proj		bDollar
	declare @sum_of_job_curr		bDollar
	declare @sum_of_job_orig		bDollar

	declare @sum_of_contract_item_proj	bDollar
	declare @sum_of_contract_item_curr		bDollar
	declare @sum_of_contract_item_orig		bDollar

	declare @PhaseGroup				tinyint
	declare @Phase					bPhase
	declare @CostType				bJCCType
	declare @ProjCost				bDollar
	declare @ActualCost				bDollar
	declare @OrigEstCost			bDollar

	declare @pct_basis					char(1)
	declare @pct						bPct

	declare @pct_total						bPct


	select
		@sum_of_job_proj=sum(jccp.ProjCost) 
	,	@sum_of_job_curr=sum(jccp.ActualCost) 
	,	@sum_of_job_orig=sum(jccp.OrigEstCost) 
	from
		JCCP jccp join
		JCCH jcch on
			jccp.JCCo=jcch.JCCo
		and jccp.Job=jcch.Job
		and jccp.PhaseGroup=jcch.PhaseGroup
		and jccp.Phase=jcch.Phase
		and jccp.CostType=jcch.CostType 
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month	
	group by
		jccp.JCCo
	,	jccp.Job
	


	declare cicur cursor for
	select
		jccp.PhaseGroup
	,	jccp.Phase
	,	jccp.CostType
	,	sum(jccp.ProjCost) as ProjCost
	,	sum(jccp.ActualCost) as ActualCost
	,	sum(jccp.OrigEstCost) as OrigEstCost
	from
		JCCP jccp join
		JCCH jcch on
			jccp.JCCo=jcch.JCCo
		and jccp.Job=jcch.Job
		and jccp.PhaseGroup=jcch.PhaseGroup
		and jccp.Phase=jcch.Phase
		and jccp.CostType=jcch.CostType
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month
	group by
		jccp.PhaseGroup
	,	jccp.Phase
	,	jccp.CostType	
	having
	(
		sum(jccp.ProjCost) <> 0
	or	sum(jccp.ActualCost) <> 0 
	or	sum(jccp.OrigEstCost) <> 0		
	)
	for read only

	OPEN cicur
	fetch cicur into
		@PhaseGroup
	,	@Phase
	,	@CostType
	,	@ProjCost				--bDollar
	,	@ActualCost				--bDollar
	,	@OrigEstCost			--bDollar		

	while @@FETCH_STATUS=0
	begin
		
		if @sum_of_job_proj <> 0
		begin
			set @pct_basis='P'
			set @pct = @ProjCost / @sum_of_job_proj

		end
		else if @sum_of_job_curr <> 0
		begin
			set @pct_basis='C'
			set @pct = @ActualCost / @sum_of_job_curr

		end
		else if @sum_of_job_orig <> 0
		begin
			set @pct_basis='O'
			set @pct = @OrigEstCost / @sum_of_job_orig
		end
		else
		begin
			set @pct_basis='X'
			set @pct = 0
		end

		print
		cast(@PhaseGroup as char(10))
	+	cast(@Phase as char(20))
	+	cast(@CostType as char(10))
	+	cast(@ProjCost as char(10))
	+	cast(@ActualCost as char(10))
	+	cast(@OrigEstCost as char(10))
	+	cast(@sum_of_job_proj as char(15))
	+	cast(@sum_of_job_curr as char(15))
	+	cast(@sum_of_job_orig as char(15))
	+	cast(@pct_basis as char(10))
	+	cast(@pct as char(10))


		update 
			JCCH 
		set
			[udPercentOfJob] = @pct
		,	[udPercentOfJobBasis] = @pct_basis
		,	[udPercentOfJobAsOf] = @Month
		where
			JCCo=@JCCo
		and Job=@Job
		and PhaseGroup=@PhaseGroup
		and Phase=@Phase
		and CostType=@CostType

		fetch cicur into
			@PhaseGroup
		,	@Phase
		,	@CostType
		,	@ProjCost				--bDollar
		,	@ActualCost				--bDollar
		,	@OrigEstCost			--bDollar		
	end

	close cicur

	select @pct_total=sum(udPercentOfJob) 
	from 
		JCCH 
	where 
		JCCo=@JCCo
	and Job=@Job

	if 1-@pct_total <> 0
	begin
		select top 1
			@PhaseGroup=PhaseGroup
		,	@Phase=Phase
		,	@CostType=CostType
		from 
			JCCH
		where 		
			JCCo=@JCCo
		and Job=@Job
		order by
			udPercentOfJob DESC

		update 
			JCCH 
		set
			udPercentOfJob = udPercentOfJob + ( 1-@pct_total )
		where
			JCCo=@JCCo
		and Job=@Job
		and PhaseGroup=@PhaseGroup
		and Phase=@Phase
		and CostType=@CostType

	end

	if @ShowResults <> 0
	begin
		set nocount off
		select * from JCCH where JCCo=@JCCo	and Job=@Job 
		select JCCo, Job, sum([udPercentOfJob]) from JCCH where JCCo=@JCCo	and Job=@Job group by JCCo, Job
	end

end

go


--Run AdHoc/One Off Updates
/*

declare @JCCo			bCompany
declare @Job			bContract
declare @Month			bMonth
declare @ShowResults	tinyint	

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'

set @Job='102741-001'
exec mspGenJCCHJobPercentage @JCCo, @Job, @Month,@ShowResults

set @Job='105675-001'
exec mspGenJCCHJobPercentage @JCCo, @Job, @Month,@ShowResults

set @Job=' 10006-001'
exec mspGenJCCHJobPercentage @JCCo, @Job, @Month,@ShowResults
*/

--Initialize All Contracts
declare ccur cursor for
select distinct JCCo, Job, cast('12/1/2015' as smalldatetime) as Month from JCJM order by 1,2 for read only

declare @JCCo bCompany
declare @Job	bJob
declare @Month	bMonth

open ccur
fetch ccur into @JCCo, @Job, @Month

while @@FETCH_STATUS=0
begin
	exec mspGenJCCHJobPercentage @JCCo, @Job, @Month,0

	fetch ccur into @JCCo, @Job, @Month
end

deallocate ccur
go






declare @JCCo			bCompany
declare @Job			bContract
declare @Month			bMonth
declare @ShowResults	tinyint	

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'

set @Job='102741-001'


	select
		sum(jccp.ProjCost) 
	,	sum(jccp.ActualCost) 
	,	sum(jccp.OrigEstCost) 
	from
		JCCP jccp join
		JCCH jcch on
			jccp.JCCo=jcch.JCCo
		and jccp.Job=jcch.Job
		and jccp.PhaseGroup=jcch.PhaseGroup
		and jccp.Phase=jcch.Phase
		and jccp.CostType=jcch.CostType
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month
	group by
		jccp.JCCo
	,	jccp.Job


	select
		jccp.PhaseGroup
	,	jccp.Phase
	,	jccp.CostType
	,	sum(jccp.ProjCost) as ProjCost
	,	sum(jccp.ActualCost) as ActualCost
	,	sum(jccp.OrigEstCost) as OrigEstCost
	from
		JCCP jccp join
		JCCH jcch on
			jccp.JCCo=jcch.JCCo
		and jccp.Job=jcch.Job
		and jccp.PhaseGroup=jcch.PhaseGroup
		and jccp.Phase=jcch.Phase
		and jccp.CostType=jcch.CostType
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month
	group by
		jccp.PhaseGroup
	,	jccp.Phase
	,	jccp.CostType		




declare @JCCo			bCompany
declare @Job			bContract
declare @Month			bMonth
declare @ShowResults	tinyint	

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'

set @Job='102741-001'

	select
		jcjp.JCCo
	,	jcjp.Contract
	,	jcjp.Item
	,	count(distinct jccp.Job) as JobCount
	,	sum(jccp.ProjCost) 
	,	sum(jccp.ActualCost) 
	,	sum(jccp.OrigEstCost) 
	from
		JCCP jccp join
		JCCH jcch on
			jccp.JCCo=jcch.JCCo
		and jccp.Job=jcch.Job
		and jccp.PhaseGroup=jcch.PhaseGroup
		and jccp.Phase=jcch.Phase
		and jccp.CostType=jcch.CostType join
		JCJP jcjp on
			jcch.JCCo=jcjp.JCCo
		and jccp.Job=jcjp.Job
		and jccp.PhaseGroup=jcjp.PhaseGroup
		and jccp.Phase=jcjp.Phase
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month
	group by
		jcjp.JCCo
	,	jcjp.Contract
	,	jcjp.Item
