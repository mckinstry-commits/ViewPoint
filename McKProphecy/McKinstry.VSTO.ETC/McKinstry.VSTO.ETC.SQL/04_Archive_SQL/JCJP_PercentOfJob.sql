

--select JCCo, Contract, count(Item) from JCCI group by JCCo, Contract having count(*)>1 order by 3 DESC

use Viewpoint
go

--Add as Viewpoint UD Fields to JC and PM JobPhases(JCJP) and JobPhase/CostType (JCCH)
/*
alter table bJCJP
add
	udPercentOfJob					decimal(12,4)	not null default 0
,	udPercentOfJobBasis				char(1)	not null default 'P'
,	udPercentOfJobAsOf				bMonth	null
,	udPercentOfContractItem			decimal(12,4)	not null default 0
,	udPercentOfContractItemBasis	char(1)	not null default 'P'
,	udPercentOfContractItemAsOf		bMonth	null
go
sp_refreshview @viewname = 'JCJP'

*/

update DDFIc set DisableInput='Y', ShowGrid='N' where Form in ('JCJP','PMProjectPhases') and ColumnName in 
(
'udPercentOfJob','udPercentOfJobBasis','udPercentOfJobAsOf',
'udPercentOfContractItem','udPercentOfContractItemBasis','udPercentOfContractItemAsOf'
)
go

if exists ( select 1 from sysobjects where type='P' and name='mspGenJCJPJobPercentage')
begin
	print 'drop procedure mspGenJCJPJobPercentage'
	drop procedure mspGenJCJPJobPercentage
end
go

print 'create procedure mspGenJCJPJobPercentage'
go

create procedure mspGenJCJPJobPercentage
(
	@JCCo			bCompany
,	@Job			bJob
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

	--print cast(@JCCo as char(5)) + cast(@Job as char(15)) + convert(varchar(10), @Month, 101)

	declare @sum_of_Projected		bDollar
	declare @sum_of_Actual			bDollar
	declare @sum_of_Original		bDollar

	declare @PhaseGroup				bGroup
	declare @Phase					bPhase
	declare @Projected				bDollar
	declare @Actual					bDollar
	declare @Original				bDollar

	declare @pct_basis				char(1)
	declare @pct					decimal(12,4)

	declare @pct_total				decimal(12,4)
	declare @max_pct				decimal(12,4)
	set @max_pct = 99999999.9999

	select 
		@sum_of_Projected = sum(jccp.ProjCost)
	,	@sum_of_Actual = sum(jccp.ActualCost)
	,	@sum_of_Original = sum(jccp.OrigEstCost)
	from
		JCCP jccp
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month

	/*

	select 
		jccp.JCCo
	,	jccp.Job
	,	sum(jccp.ProjCost)
	,	sum(jccp.ActualCost)
	,	sum(jccp.OrigEstCost)
	
	from
		JCCP jccp
	where
		jccp.Mth<='12/1/2015'
	and jccp.Job=' 15416-001'
	group by JCCo, Job


	select 
		jccp.JCCo
	,	jccp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	,	sum(jccp.ProjCost)
	,	sum(jccp.ActualCost)
	,	sum(jccp.OrigEstCost)
	from
		JCCP jccp
	where
		jccp.Mth<='12/1/2015'
	and jccp.Job=' 15416-001'
	group by JCCo, Job, PhaseGroup, Phase

	*/

	declare cicur cursor for
	select
		jccp.PhaseGroup
	,	jccp.Phase
	,	sum(jccp.ProjCost) as ProjDollars
	,	sum(jccp.ActualCost) as ContractAmt
	,	sum(jccp.OrigEstCost) as OrigContractAmt
	from
		JCCP jccp
	where
		jccp.JCCo=@JCCo
	and jccp.Job=@Job
	and jccp.Mth<=@Month
	group by
		jccp.JCCo
	,	jccp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	order by
		jccp.JCCo
	,	jccp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	for read only

	OPEN cicur
	fetch cicur into
		@PhaseGroup			--bGroup
	,	@Phase				--bPhase
	,	@Projected			--bDollar
	,	@Actual				--bDollar
	,	@Original			--bDollar		

	while @@FETCH_STATUS=0
	begin

		if @sum_of_Projected <> 0
		begin
			set @pct_basis='P'
			if abs(@Projected / @sum_of_Projected) <= @max_pct
				set @pct = @Projected / @sum_of_Projected
			else
				set @pct = 0

		end
		else if @sum_of_Actual <> 0
		begin
			set @pct_basis='C'
			if abs(@Actual / @sum_of_Actual) <= @max_pct
				set @pct = @Actual / @sum_of_Actual
			else
				set @pct=0

		end
		else if @sum_of_Original <> 0
		begin
			set @pct_basis='O'
			if abs(@Original / @sum_of_Original) <= @max_pct
				set @pct = @Original / @sum_of_Original
			else
				set @pct=0
		end
		else
		begin
			set @pct_basis='X'
			set @pct = 0
		end

		print	
			cast(@JCCo as char(5)) 
		+	cast(@Job as char(15)) 
		+	cast(@PhaseGroup as char(15)) 
		+	cast(@Phase as char(15)) 
		+	convert(char(10), @Month, 101) + '    ' 
		+	cast(@pct_basis as char(5))		
		+	cast(@pct as char(10))
		+	cast(@Projected as char(20))
		+	cast(@sum_of_Projected as char(20))
		+	cast(@Actual as char(20))
		+	cast(@sum_of_Actual as char(20))
		+	cast(@Original as char(20))
		+	cast(@sum_of_Original as char(20))

		update 
			JCJP
		set
			udPercentOfJob = @pct
		,	udPercentOfJobBasis = @pct_basis
		,	udPercentOfJobAsOf = @Month
		where
			JCCo=@JCCo
		and Job=@Job
		and PhaseGroup=@PhaseGroup
		and Phase=@Phase


		fetch cicur into
			@PhaseGroup			--bGroup
		,	@Phase				--bPhase
		,	@Projected			--bDollar
		,	@Actual				--bDollar
		,	@Original			--bDollar	
	end

	close cicur

	select @pct_total=sum(udPercentOfJob) 
	from 
		JCJP 
	where 
		JCCo=@JCCo
	and Job=@Job

	if 1-@pct_total <> 0
	begin
		select top 1
			@PhaseGroup=PhaseGroup
		,	@Phase=Phase
		from 
			JCJP 
		where 		
			JCCo=@JCCo
		and Job=@Job
		order by
			udPercentOfJob DESC

		update 
			JCJP
		set
			udPercentOfJob = udPercentOfJob + ( 1-@pct_total )
		where
			JCCo=@JCCo
		and Job=@Job
		and PhaseGroup=@PhaseGroup
		and Phase=@Phase

	end

	if @ShowResults <> 0
	begin
		set nocount off
		select * from JCJP where JCCo=@JCCo	and Job=@Job
	end

end

go


--Run AdHoc/One Off Updates
/*
declare @JCCo bCompany
declare @Job	bJob
declare @Month	bMonth
declare @ShowResults tinyint

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'


set @Job=' 15416-001'
exec mspGenJCJPJobPercentage @JCCo, @Job, @Month,@ShowResults


set @Job='102741-001'
exec mspGenJCJPJobPercentage @JCCo, @Job, @Month,@ShowResults

set @Job='105675-001'
exec mspGenJCJPJobPercentage @JCCo, @Job, @Month,@ShowResults

set @Job=' 10006-001'
exec mspGenJCJPJobPercentage @JCCo, @Job, @Month,@ShowResults
*/

--Initialize All Jobs
declare ccur cursor for
select distinct JCCo, Job, cast('12/1/2015' as smalldatetime) as Month from JCJM order by 1,2 for read only

declare @JCCo bCompany
declare @Job	bJob
declare @Month	bMonth

open ccur
fetch ccur into @JCCo, @Job, @Month

while @@FETCH_STATUS=0
begin
	exec mspGenJCJPJobPercentage @JCCo, @Job, @Month,0

	fetch ccur into @JCCo, @Job, @Month
end

deallocate ccur
go


