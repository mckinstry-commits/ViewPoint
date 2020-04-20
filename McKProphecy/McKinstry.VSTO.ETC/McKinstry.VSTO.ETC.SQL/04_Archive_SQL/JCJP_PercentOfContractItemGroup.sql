

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
,	udPercentOfContractItemGroup			decimal(12,4)	not null default 0
,	udPercentOfContractItemGroupBasis	char(1)	not null default 'P'
,	udPercentOfContractItemGroupAsOf		bMonth	null

go
sp_refreshview @viewname = 'JCJP'

*/


update DDFIc set DisableInput='Y', ShowGrid='N' where Form in ('JCJP','PMProjectPhases') and ColumnName in 
(
'udPercentOfJob','udPercentOfJobBasis','udPercentOfJobAsOf',
'udPercentOfContractItem','udPercentOfContractItemBasis','udPercentOfContractItemAsOf',
'udPercentOfContractItemGroup','udPercentOfContractItemGroupBasis','udPercentOfContractItemGroupAsOf'
)
go

if exists ( select 1 from sysobjects where type='P' and name='mspGenJCJPContractItemGroupPercentage')
begin
	print 'drop procedure mspGenJCJPContractItemGroupPercentage'
	drop procedure mspGenJCJPContractItemGroupPercentage
end
go

print 'create procedure mspGenJCJPContractItemGroupPercentage'
go

create procedure [dbo].[mspGenJCJPContractItemGroupPercentage]
(
	@JCCo			bCompany
,	@Contract		bContract
,	@ItemGroup		varchar(16)
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

	declare @Job					bJob
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
		JCCP jccp join
		JCJP jcjp on
			jccp.JCCo=jcjp.JCCo
		and jccp.Job=jcjp.Job
		and jccp.PhaseGroup=jcjp.PhaseGroup
		and jccp.Phase=jcjp.Phase join
	JCCI jcci on
		jcjp.JCCo=jcci.JCCo
	and jcjp.Contract=jcci.Contract
	and jcjp.Item=jcci.Item
	where
		jcci.JCCo=@JCCo
	and jcci.Contract=@Contract
	and coalesce(jcci.udItemGroup, jcci.Item)=@ItemGroup
	and jccp.Mth<=@Month
	group by
		jcci.JCCo
	,	jcci.Contract
	,	coalesce(jcci.udItemGroup, jcci.Item) 

	declare cicur cursor for

	select 
		jcjp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	,	sum(jccp.ProjCost)
	,	sum(jccp.ActualCost)
	,	sum(jccp.OrigEstCost)
	from
		JCCP jccp join
		JCJP jcjp on
			jccp.JCCo=jcjp.JCCo
		and jccp.Job=jcjp.Job
		and jccp.PhaseGroup=jcjp.PhaseGroup
		and jccp.Phase=jcjp.Phase join
		JCCI jcci on
			jcjp.JCCo=jcci.JCCo
		and jcjp.Contract=jcci.Contract
		and jcjp.Item=jcci.Item
	where
		jcjp.JCCo=@JCCo
	and jcjp.Contract=@Contract
	and coalesce(jcci.udItemGroup, jcci.Item)=@ItemGroup
	and jccp.Mth<=@Month
	group by
		jcci.JCCo
	,	jcci.Contract
	,	coalesce(jcci.udItemGroup, jcci.Item) 
	,	jcjp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	order by
		jcci.JCCo
	,	jcjp.Job
	,	jccp.PhaseGroup
	,	jccp.Phase
	for read only


	OPEN cicur
	fetch cicur into
		@Job
	,	@PhaseGroup			--bGroup
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
				set @pct = 0

		end
		else if @sum_of_Original <> 0
		begin
			set @pct_basis='O'
			if abs(@Original / @sum_of_Original) <= @max_pct
				set @pct = @Original / @sum_of_Original
			else
				set @pct = 0
		end
		else
		begin
			set @pct_basis='X'
			set @pct = 0
		end

		print	
			cast(@JCCo as char(5)) 
		+	cast(@Contract as char(15)) 
		+	cast(@ItemGroup as char(15)) 
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
			udPercentOfContractItemGroup = @pct
		,	udPercentOfContractItemGroupBasis = @pct_basis
		,	udPercentOfContractItemGroupAsOf = @Month
		where
			JCCo=@JCCo
		and Job=@Job
		and PhaseGroup=@PhaseGroup
		and Phase=@Phase


		fetch cicur into
			@Job
		,	@PhaseGroup			--bGroup
		,	@Phase				--bPhase
		,	@Projected			--bDollar
		,	@Actual				--bDollar
		,	@Original			--bDollar	
	end

	close cicur

	select @pct_total=sum(jcjp.udPercentOfContractItemGroup) 
	from 
		JCJP jcjp join
		JCCI jcci on
			jcjp.JCCo=jcci.JCCo
		and jcjp.Contract=jcci.Contract
		and jcjp.Item=jcci.Item
	where 
		jcjp.JCCo=@JCCo
	and jcjp.Contract=@Contract
	and coalesce(jcci.udItemGroup, jcci.Item)=@ItemGroup

	if 1-@pct_total <> 0
	begin
		select top 1
			@Job = jcjp.Job
		,	@PhaseGroup=jcjp.PhaseGroup
		,	@Phase=jcjp.Phase
		from 
			JCJP jcjp join
			JCCI jcci on
				jcjp.JCCo=jcci.JCCo
			and jcjp.Contract=jcci.Contract
			and jcjp.Item=jcci.Item
		where 		
			jcjp.JCCo=@JCCo
		and jcjp.Contract=@Contract
		and coalesce(jcci.udItemGroup, jcci.Item)=@ItemGroup
		order by
			jcjp.udPercentOfContractItemGroup DESC

		update 
			JCJP
		set
			udPercentOfContractItemGroup = udPercentOfContractItemGroup + ( 1-@pct_total )
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


GO



--Run AdHoc/One Off Updates
/*
declare @JCCo bCompany
declare @Contract	bContract
declare @Item	bContractItem
declare @Month	bMonth
declare @ShowResults tinyint

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'

set @Contract=' 10061-'
set @Item='               5'
exec mspGenJCJPContractItemPercentage @JCCo, @Contract, @Item, @Month,@ShowResults

select JCCo, Contract, Job, sum(udPercentOfContractItem) PctOfCI, sum(udPercentOfJob) as PctOfJob from JCJP where JCCo=@JCCo and Contract=@Contract group by JCCo, Contract, Job

set @Job='102741-001'
exec mspGenJCJPContractItemPercentage @JCCo, @Job, @Month,@ShowResults

set @Job='105675-001'
exec mspGenJCJPContractItemPercentage @JCCo, @Job, @Month,@ShowResults

set @Job=' 10006-001'
exec mspGenJCJPContractItemPercentage @JCCo, @Job, @Month,@ShowResults
*/

/*
--Initialize All Jobs
declare ccur cursor for
select distinct JCCo, Contract, coalesce(udItemGroup,Item), cast('12/1/2015' as smalldatetime) as Month from JCCI where JCCo=222 order by 1,2,3 for read only

declare @JCCo bCompany
declare @Contract	bContract
declare @ItemGroup	varchar(16)
declare @Month	bMonth

open ccur
fetch ccur into @JCCo, @Contract, @ItemGroup, @Month

while @@FETCH_STATUS=0
begin
	exec mspGenJCJPContractItemGroupPercentage @JCCo, @Contract, @ItemGroup, @Month,0

	fetch ccur into @JCCo, @Contract, @ItemGroup, @Month
end

deallocate ccur
go


*/