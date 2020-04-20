-- JC Revenue Projections Detail
--  * Model after JCPR (Cost Projection Detail)
--  * Child of JCIR for posted persistent 
--  * Child of JCIR Batch Table for transational posting process
use Viewpoint 
go
drop procedure mspGenJCIPDEntries
create procedure mspGenJCIPDEntries
(
	@projMonth	bMonth
,	@co			bCompany
,	@contract	bContract

)
as

--select @projMonth='1/1/2016', @co=1, @contract=''

declare contract_cur cursor for
select
	jccm.JCCo
,	jccm.Contract
,	@projMonth as Mth
,	case when coalesce(jccm.StartMonth, jccm.StartDate) is null then @projMonth else coalesce(jccm.StartMonth, jccm.StartDate) end as ContractStartDate
,	case when jccm.ProjCloseDate is null then @projMonth else jccm.ProjCloseDate end as ContractProjectedCloseDate
,	datediff(
		month
	,case when coalesce(jccm.StartMonth, jccm.StartDate) is null then @projMonth else coalesce(jccm.StartMonth, jccm.StartDate) end 
	,case when jccm.ProjCloseDate is null then @projMonth else jccm.ProjCloseDate end
	) as ContractDuration
,	jcci.Item
,	coalesce(sum(jcip.ProjDollars), jccm.ContractAmt) as ProjDollars
,	coalesce(sum(jcip.ProjUnits),0) as ProjDollars
from
	JCCM jccm join
	JCCI jcci on
		jccm.JCCo=jcci.JCCo
	and jccm.Contract=jcci.Contract join
	JCIP jcip on
		jcci.JCCo=jcip.JCCo
	and jcci.Contract=jcip.Contract
	and jcci.Item=jcip.Item
	and jcip.Mth <= @projMonth
where
	jccm.JCCo=@co
and jccm.Contract=@contract
group by
	jccm.JCCo
,	jccm.Contract
,	coalesce(jccm.StartMonth, jccm.StartDate)
,	jccm.ProjCloseDate
,	jcci.Item
,	jccm.ContractAmt
for read only

declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth
declare @StartDate bDate
declare @CloseDate bDate
declare @Duration int
declare @Item bContractItem
declare @ProjDollars bDollar
declare @ProjUnits bUnits

declare @counter int
set @counter=0

open contract_cur
fetch contract_cur into
	@JCCo 
,	@Contract 
,	@Month
,	@StartDate 
,	@CloseDate 
,	@Duration 
,	@Item 
,	@ProjDollars 
,	@ProjUnits 

while @@FETCH_STATUS=0
begin

	select @StartDate = CAST(cast(MONTH(@StartDate) as varchar(2)) + '/1/' + cast(YEAR(@StartDate) as varchar(4)) as datetime)
	select @counter = 0

	while @counter <  @Duration
	begin

		insert budJCIPD ( Co,	Mth,	Contract,	Item,	FromDate,	ToDate,	ProjDollars,	ProjUnits )
		select @JCCo, @Month, @Contract, @Item, dateadd(month,@counter,@StartDate),  dateadd(day, -1, dateadd(month,@counter+1,@StartDate)),@ProjDollars/@Duration, @ProjUnits/@Duration
	
		select @counter=@counter+1
	end

	fetch contract_cur into
		@JCCo 
	,	@Contract 
	,	@Month
	,	@StartDate 
	,	@CloseDate 
	,	@Duration 
	,	@Item 
	,	@ProjDollars 
	,	@ProjUnits 

end

close contract_cur
go

create procedure mspGenJCIRDEntries
(
	@projMonth	bMonth
,	@co			bCompany
,	@contract	bContract
,	@batchid	bBatchID
)
as

--select @projMonth='1/1/2016', @co=1, @contract=''

declare contract_cur cursor for
select
	jccm.JCCo
,	jccm.Contract
,	@projMonth as Mth
,	case when jccm.StartDate is null then @projMonth else jccm.StartDate end as ContractStartDate
,	case when jccm.ProjCloseDate is null then @projMonth else jccm.ProjCloseDate end as ContractProjectedCloseDate
,	datediff(
		month
	,case when jccm.StartDate is null then @projMonth else jccm.StartDate end 
	,case when jccm.ProjCloseDate is null then @projMonth else jccm.ProjCloseDate end
	) as ContractDuration
,	jcci.Item
,	coalesce(sum(jcip.ProjDollars), jccm.ContractAmt) as ProjDollars
,	coalesce(sum(jcip.ProjUnits),0) as ProjUnits
from
	JCCM jccm join
	JCCI jcci on
		jccm.JCCo=jcci.JCCo
	and jccm.Contract=jcci.Contract join
	JCIP jcip on
		jcci.JCCo=jcip.JCCo
	and jcci.Contract=jcip.Contract
	and jcci.Item=jcip.Item
	and jcip.Mth <= @projMonth
where
	jccm.JCCo=@co
and jccm.Contract=@contract
group by
	jccm.JCCo
,	jccm.Contract
,	jccm.StartDate
,	jccm.ProjCloseDate
,	jcci.Item
,	jccm.ContractAmt
for read only

declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth
declare @StartDate bDate
declare @CloseDate bDate
declare @Duration int
declare @Item bContractItem
declare @ProjDollars bDollar
declare @ProjUnits bUnits

declare @batch_seq int

declare @counter int
set @counter=0

open contract_cur
fetch contract_cur into
	@JCCo 
,	@Contract 
,	@Month
,	@StartDate 
,	@CloseDate 
,	@Duration 
,	@Item 
,	@ProjDollars 
,	@ProjUnits 

while @@FETCH_STATUS=0
begin

	select @StartDate = CAST(cast(MONTH(@StartDate) as varchar(2)) + '/1/' + cast(YEAR(@StartDate) as varchar(4)) as datetime)
	select @counter = 0

	select @batch_seq=BatchSeq from JCIR where Co=@JCCo and Contract=@Contract and Item=@Item and BatchId=@batchid

	while @counter <  @Duration
	begin

		insert budJCIRD ( BatchId, BatchSeq, Co,	Mth,	Contract,	Item,	FromDate,	ToDate,	ProjDollars,	ProjUnits )
		select @batchid, @batch_seq, @JCCo, @Month, @Contract, @Item, dateadd(month,@counter,@StartDate),  dateadd(day, -1, dateadd(month,@counter+1,@StartDate)),@ProjDollars/@Duration, @ProjUnits/@Duration
	
		select @counter=@counter+1
	end

	fetch contract_cur into
		@JCCo 
	,	@Contract 
	,	@Month
	,	@StartDate 
	,	@CloseDate 
	,	@Duration 
	,	@Item 
	,	@ProjDollars 
	,	@ProjUnits 

end

close contract_cur
go


exec mspGenJCIPDEntries @co=1, @contract=' 14345-', @projMonth='1/1/2016';
exec mspGenJCIRDEntries @co=1, @contract=' 14345-', @projMonth='1/1/2016', @batchid=3864;

