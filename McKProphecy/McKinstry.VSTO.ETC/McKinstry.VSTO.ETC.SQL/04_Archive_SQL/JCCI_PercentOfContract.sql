

--select JCCo, Contract, count(Item) from JCCI group by JCCo, Contract having count(*)>1 order by 3 DESC

use Viewpoint
go

--Add as Viewpoint UD Fields to JC and PM Contract Items
/*
alter table bJCCI
add
	udPercentOfContract			decimal(12,4)	not null default 0
,	udPercentOfContractBasis	char(1)	not null default 'P'
,	udPercentOfContractAsOf		bMonth	null 
go
sp_refreshview @viewname = 'JCCI'
*/

--After adding Form Fields, make them disabled
update DDFIc set DisableInput='Y' where Form='JCCI' and ColumnName in ('udPercentOfContract','udPercentOfContractBasis','udPercentOfContractAsOf')


if exists ( select 1 from sysobjects where type='P' and name='mspGenJCCIContractPercentage')
begin
	print 'drop procedure mspGenJCCIContractPercentage'
	drop procedure mspGenJCCIContractPercentage
end
go

print 'create procedure mspGenJCCIContractPercentage'
go

create procedure mspGenJCCIContractPercentage
(
	@JCCo			bCompany
,	@Contract		bContract
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

	print cast(@JCCo as char(5)) + cast(@Contract as char(15)) + convert(varchar(10), @Month, 101)

	declare @sum_of_contract_item_proj	bDollar
	declare @sum_of_contract_item_curr		bDollar
	declare @sum_of_contract_item_orig		bDollar

	declare @Item						bContractItem
	declare @ProjDollars				bDollar
	declare @ContractAmt				bDollar
	declare @OrigContractAmt			bDollar

	declare @pct_basis					char(1)
	declare @pct						decimal(12,4)

	declare @pct_total						decimal(12,4)

	select 
		@sum_of_contract_item_proj = sum(jcip.ProjDollars)
	,	@sum_of_contract_item_curr = sum(jcip.ContractAmt)
	,	@sum_of_contract_item_orig = sum(jcip.OrigContractAmt)
	from
		JCIP jcip
	where
		jcip.JCCo=@JCCo
	and jcip.Contract=@Contract
	and jcip.Mth<=@Month

	declare cicur cursor for
	select
		jcip.Item
	,	sum(jcip.ProjDollars) as ProjDollars
	,	sum(jcip.ContractAmt) as ContractAmt
	,	sum(jcip.OrigContractAmt) as OrigContractAmt
	from
		JCIP jcip
	where
		jcip.JCCo=@JCCo
	and jcip.Contract=@Contract
	and jcip.Mth<=@Month
	group by
		jcip.JCCo
	,	jcip.Contract
	,	jcip.Item
	order by
		jcip.Item
	for read only

	OPEN cicur
	fetch cicur into
		@Item						--bContractItem
	,	@ProjDollars				--bDollar
	,	@ContractAmt				--bDollar
	,	@OrigContractAmt			--bDollar		

	while @@FETCH_STATUS=0
	begin
		
		if @sum_of_contract_item_proj <> 0
		begin
			set @pct_basis='P'
			set @pct = @ProjDollars / @sum_of_contract_item_proj

		end
		else if @sum_of_contract_item_curr <> 0
		begin
			set @pct_basis='C'
			set @pct = @ContractAmt / @sum_of_contract_item_curr

		end
		else if @sum_of_contract_item_orig <> 0
		begin
			set @pct_basis='O'
			set @pct = @OrigContractAmt / @sum_of_contract_item_orig
		end
		else
		begin
			set @pct_basis='X'
			set @pct = 0
		end

		update 
			JCCI 
		set
			udPercentOfContract = @pct
		,	udPercentOfContractBasis = @pct_basis
		,	udPercentOfContractAsOf = @Month
		where
			JCCo=@JCCo
		and Contract=@Contract
		and Item=@Item

		fetch cicur into
			@Item						--bContractItem
		,	@ProjDollars				--bDollar
		,	@ContractAmt				--bDollar
		,	@OrigContractAmt			--bDollar	
	end

	close cicur

	select @pct_total=sum(udPercentOfContract) 
	from 
		JCCI 
	where 
		JCCo=@JCCo
	and Contract=@Contract

	if 1-@pct_total <> 0
	begin
		select top 1
			@Item=Item 
		from 
			JCCI 
		where 		
			JCCo=@JCCo
		and Contract=@Contract
		order by
			udPercentOfContract DESC

		update 
			JCCI 
		set
			udPercentOfContract = udPercentOfContract + ( 1-@pct_total )
		where
			JCCo=@JCCo
		and Contract=@Contract
		and Item=@Item

	end

	if @ShowResults <> 0
	begin
		set nocount off
		select * from JCCI where JCCo=@JCCo	and Contract=@Contract 
	end

end

go


-- Create Triggers on JCIP to trigger update of percentage if 	JCIP.ProjDollars,JCIP.ContractAmt or JCIP.OrigContractAmt is added, updated or deleted.


--drop trigger mtrJCIPi
--go

--create trigger mtrJCIPi on bJCIP 
--after INSERT
--as

--declare @JCCo bCompany
--declare @Contract bContract
--declare @Month bMonth

--select
--	@JCCo=i.JCCo
--,	@Contract=i.Contract
--,	@Month=i.Mth
--from
--	inserted i join
--	JCIP jcip on
--		i.JCCo=jcip.JCCo
--	and i.Contract=jcip.Contract
--	and i.Item=jcip.Item
--	and i.Mth=jcip.Mth
--where
--	i.ProjDollars		<>	jcip.ProjDollars
--or	i.ContractAmt		<>	jcip.ContractAmt
--or	i.OrigContractAmt	<>	jcip.OrigContractAmt


--exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,0

--go

--drop trigger mtrJCIPu
--go

--create trigger mtrJCIPu on bJCIP 
--after INSERT
--as

--declare @JCCo bCompany
--declare @Contract bContract
--declare @Month bMonth

--select
--	@JCCo=i.JCCo
--,	@Contract=i.Contract
--,	@Month=i.Mth
--from
--	inserted i join
--	JCIP jcip on
--		i.JCCo=jcip.JCCo
--	and i.Contract=jcip.Contract
--	and i.Item=jcip.Item
--	and i.Mth=jcip.Mth
--where
--	i.ProjDollars		<>	jcip.ProjDollars
--or	i.ContractAmt		<>	jcip.ContractAmt
--or	i.OrigContractAmt	<>	jcip.OrigContractAmt


--exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,0

--go

--drop trigger mtrJCIPd

--create trigger mtrJCIPd on bJCIP 
--for delete
--as
--	declare jcip_cur cursor for
--	select distinct
--		JCCo
--	,	Contract
--	,	Mth
--	from 
--		deleted
--	order by
--		JCCo
--	,	Contract
--	for read only

--	declare @JCCo bCompany
--	declare @Contract bContract
--	declare @Month bMonth

--	open jcip_cur
--	fetch jcip_cur into
--		@JCCo
--	,	@Contract
--	,	@Month

--	while @@fetch_status = 0
--	begin

--		exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,0

--		fetch jcip_cur into
--			@JCCo
--		,	@Contract
--		,	@Month

--	end

--	close jcip_cur
--	deallocate jcip_cur
--go



--Run AdHoc/One Off Updates
/*
declare @JCCo bCompany
declare @Contract	bContract
declare @Month	bMonth
declare @ShowResults tinyint

set @ShowResults=1
set @JCCo=1
set @Month = '12/1/2015'

set @Contract='102741-'
exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,@ShowResults

set @Contract='105675-'
exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,@ShowResults

set @Contract=' 10006-'
exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,@ShowResults
*/

--Initialize All Contracts
declare ccur cursor for
select distinct JCCo, Contract, cast('12/1/2015' as smalldatetime) as Month 
from JCCM 
--where Contract=' 14345-'
order by 1,2 for read only

declare @JCCo bCompany
declare @Contract	bContract
declare @Month	bMonth

open ccur
fetch ccur into @JCCo, @Contract, @Month

while @@FETCH_STATUS=0
begin
	exec mspGenJCCIContractPercentage @JCCo, @Contract, @Month,0

	fetch ccur into @JCCo, @Contract, @Month
end

deallocate ccur
go



--select * from JCCI where Contract=' 14345-' and JCCo=1
--select * from JCIP where Contract=' 14345-' and JCCo=1

--update JCIP set ProjDollars=7001 where Contract=' 14345-' and JCCo=1 and Item='               5'

--select * from JCCI where Contract=' 14345-' and JCCo=1
--select * from JCIP where Contract=' 14345-' and JCCo=1

--SELECT MAX(Mth) from JCIP where Contract=' 14345-' and JCCo=1

