SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[bspJCRevProjCalc]
/****************************************************************************
* Created By: 	DANF	03/08/2005
* Modified By:  DANF	09/22/05 - Issue #29112 Change the Calculation of Units from Cost Projections
*				CHS		04/08/08 - Issue #123525 - add Project plus Markup Percent
*				CHS		04/11/08 - Issue #124378 - by department
*				CHS		06/25/08 - Issue #123525 - count as initialized if value is not zero
*				CHS		09/08/08 - Issue #129557 - needs to calculate if units are zero.
*				GF		10/03/2008 - issue #126236 use PMSC included in projection values
*				GF	03/10/2010 - issue #138401 CO units should only be included when UM match
*				GF 10/15/2010 - issue #141676 do not initialize contract in another batch
*
*
*
* USAGE:
* 	Initializes Revenue Projections for all contracts, specified range of contracts, all items,
*	specified rage of items, all bill types, or selected bill types. Then adds any entries that
*  are different from previous to the batch table JCIR. Deletes all future revenue projections
*  for any contract / item combo. Restricts to open contracts.
*
* INPUT PARAMETERS:
*	Company, Month, Batchid, User, Actual Date, Write Over Plug, Method, Markup, Bill Type,
*	Beginning Contract, Ending Contract, Beginning Item, and Ending Item.
*
* OUTPUT PARAMETERS:
*	None
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@jcco bCompany, @mth bMonth, @batchid bBatchID, @username bVPUserName=null, @actualdate datetime,
 @writeoverplug char(1), @method char(1), @markup bPct, @billtype char(1),
 @bcontract bContract, @econtract bContract, @bitem bContractItem, @eitem bContractItem, 
 @bdepartment bDept, @edepartment bDept, @msg varchar(255) output)
as
set nocount on


declare @rcode int, @opencursor int, @initcount int, @cco bCompany, @ccontract bContract, @citem bContractItem,
		@cum bUM, @cprevrevprojunits bUnits, @cprevrevprojdollars bDollar, @cbilledunits bUnits,
		@cbilleddollars bDollar, @ccostprojunits bUnits, @cactualcost bDollar, @cplugged char(1),
		@crevprojunits bUnits, @crevprojdollars bDollar, @cunitprice bUnitCost, @markupdollars bDollar,
		@ibilltype bBillType, @iplugged char(1), @ccostestunits bUnits, @itemestunits bUnits,
		@batchseq int, @department bDept, @revprojcost bDollar,
		@includedcounits bUnits, @includedcocosts bDollar



select @rcode = 0, @opencursor = 0

-- validate company
if not exists (select 1 from dbo.bJCCO with (nolock) where JCCo=@jcco)
	begin
	select @msg = 'Company not set up in JC Company file!', @rcode = 1
	goto bspexit
	end

if @username is null
	begin
	select @msg = 'User Name is invalid!', @rcode=1
	goto bspexit
	end


CREATE TABLE #tmpRevProj(
	Co					tinyint			NOT NULL,
	Contract 			varchar(10) 	NOT NULL,
	Item 				varchar(16) 	NOT NULL,
	UM					varchar(3)		NOT NULL,
	UnitPrice			decimal (16,5) 	NOT NULL,
	PrevRevProjUnits 	decimal (16,5) 	NOT NULL,
	PrevRevProjDollars 	decimal (16,5) 	NOT NULL,
	BilledUnits			decimal (16,5)	NOT NULL,
	BilledDollars		decimal (16,5)	NOT NULL,
	CostProjUnits		decimal (16,5)	NOT NULL,
	CostEstUnits		decimal (16,5)	NOT NULL,
	ActualCost			decimal (16,5)	NOT NULL,
	Plugged				char(1)			NULL,
	Department			varchar(10)		NULL,
	RevProjDollars		decimal (16,5) 	NOT NULL
   )


CREATE UNIQUE INDEX bitmpRevProj ON #tmpRevProj (Co, Contract, Item)

-- insert Temp table with projections.
insert into #tmpRevProj 
select p.JCCo, p.Contract, p.Item, i.UM,
	isnull(i.UnitPrice,0) as 'Unit Price',
	isnull(sum(p.ProjUnits),0) as 'Revenue Projected Units', 
	isnull(sum(p.ProjDollars),0) as 'Revenue Projected Dollars', 
	isnull(sum(p.BilledUnits),0) as 'Billed Units',
	isnull(sum(p.BilledAmt),0) as 'Billed Amount',

	(select isnull(sum(pu.ProjUnits),0) from dbo.bJCCP pu with (nolock)
	join dbo.bJCCH ch with (nolock) on pu.JCCo=ch.JCCo and pu.Job=ch.Job and pu.Phase=ch.Phase and pu.PhaseGroup=ch.PhaseGroup and pu.CostType=ch.CostType
	join dbo.bJCJP jp with (nolock) on pu.JCCo=jp.JCCo and pu.Job=jp.Job and pu.Phase=jp.Phase and pu.PhaseGroup=jp.PhaseGroup
	where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item and pu.Mth<=@mth and ch.ItemUnitFlag = 'Y') as 'Cost Projected Units',

	(select isnull(sum(pu.CurrEstUnits),0) from dbo.bJCCP pu with (nolock)
	join dbo.bJCCH ch with (nolock) on pu.JCCo=ch.JCCo and pu.Job=ch.Job and pu.Phase=ch.Phase and pu.PhaseGroup=ch.PhaseGroup and pu.CostType=ch.CostType
	join dbo.bJCJP jp with (nolock) on pu.JCCo=jp.JCCo and pu.Job=jp.Job and pu.Phase=jp.Phase and pu.PhaseGroup=jp.PhaseGroup
	where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item and pu.Mth<=@mth and ch.ItemUnitFlag = 'Y') as 'Cost Current Estimated Units',

	(select isnull(sum(c.ActualCost),0) 
	from dbo.bJCCP c with (nolock)
	join dbo.bJCJP jp with (nolock) on c.JCCo=jp.JCCo and c.Job=jp.Job and c.Phase=jp.Phase and c.PhaseGroup=jp.PhaseGroup
	where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item and c.Mth<=@mth) as 'Actual Cost',

	i.ProjPlug, i.Department,

	(select isnull(sum(pu.ProjCost),0) from dbo.bJCCP pu with (nolock)
	join dbo.bJCCH ch with (nolock) on pu.JCCo=ch.JCCo and pu.Job=ch.Job and pu.Phase=ch.Phase and pu.PhaseGroup=ch.PhaseGroup and pu.CostType=ch.CostType
	join dbo.bJCJP jp with (nolock) on pu.JCCo=jp.JCCo and pu.Job=jp.Job and pu.Phase=jp.Phase and pu.PhaseGroup=jp.PhaseGroup
	where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item) as 'Revenue Projected Dollars'

from dbo.bJCIP p with (nolock)
join dbo.bJCCI i with (nolock) on p.JCCo=i.JCCo and p.Contract=i.Contract and p.Item = i.Item
join dbo.bJCCM j with (nolock) on p.JCCo=j.JCCo and p.Contract=j.Contract
where p.JCCo=@jcco and p.Mth<=@mth 
and p.Contract >= isnull(@bcontract,p.Contract) and p.Contract <= isnull(@econtract,p.Contract)
and p.Item >= isnull(@bitem,p.Item) and p.Item <= isnull(@eitem,p.Item)
and i.Department >= isnull(@bdepartment, i.Department) and i.Department <= isnull(@edepartment, i.Department)
and j.ContractStatus = 1
----#141676
and not exists(select 1 from dbo.bJCIR r with (nolock) where r.Co=p.JCCo and r.Contract=p.Contract
					and (r.Mth<>@mth or (r.BatchId <> @batchid and r.Mth = @mth)))
Group by p.JCCo, p.Contract, p.Item, i.UM, i.UnitPrice, i.ProjPlug, i.Department


-- declare cursor on #tmpProjInit for Projection calculations and initialize
declare bctmpRevProj cursor local fast_forward
	for select 	T.Co, T.Contract, T.Item, T.UM, T.UnitPrice, T.PrevRevProjUnits, T.PrevRevProjDollars, 
				T.BilledUnits, T.BilledDollars, T.CostProjUnits, T.CostEstUnits, T.ActualCost, T.Plugged,
				I.BillType, I.ContractUnits, T.Department, T.RevProjDollars
from #tmpRevProj T
join bJCCI I with (nolock) on T.Co=I.JCCo and T.Contract=I.Contract and T.Item=I.Item

-- open cursor and set cursor flag
open bctmpRevProj
select @opencursor = 1, @initcount = 0

-- loop through all rows in #tmpProjInit
revcalcloop:
fetch next from bctmpRevProj into @cco, @ccontract, @citem, @cum, @cunitprice, 
		@cprevrevprojunits, @cprevrevprojdollars, @cbilledunits, @cbilleddollars,
		@ccostprojunits, @ccostestunits, @cactualcost, @cplugged, @ibilltype, @itemestunits,
		@department, @revprojcost

if (@@fetch_status <> 0) goto revcalcend

if @billtype <> 'A'
	begin
	if @billtype='P' and @ibilltype<>'P' goto revcalcloop
	if @billtype='T' and (@ibilltype<>'T' and @ibilltype<>'B') goto revcalcloop
	end

select @iplugged=isnull(RevProjPlugged,'')
from bJCIR r with (nolock)
where Co = @cco and Contract = @ccontract and Item = @citem and Mth = @mth and BatchId = @batchid

if @writeoverplug='N' and (@iplugged = 'Y' or (@iplugged = '' and @cplugged='Y')) goto revcalcloop

set @includedcounits = 0
set @includedcocosts = 0
---- get future change order values #126236
---- get pending values from PMOI where not approved and not fixed
----#138401
select @includedcocosts=isnull(sum(i.PendingAmount),0),
	   @includedcounits=isnull(sum(case when i.UM=c.UM then i.Units else 0 end),0)
	   ----@includedcounits=isnull(sum(i.Units),0)
from bPMOI i with (nolock) 
join bPMSC s with (nolock) on s.Status=i.Status
left join bPMDT t with (nolock) on t.DocType=i.PCOType
JOIN bJCCI c WITH (NOLOCK) ON c.JCCo=i.PMCo AND c.Contract=i.Contract AND c.Item=i.ContractItem
where i.PMCo=@cco and i.Contract=@ccontract and i.ContractItem=@citem
and isnull(i.ACOItem,'') = '' and i.FixedAmountYN <> 'Y'
and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y') = 'Y'

---- get pending values from PMOI where not approved and fixed
----#138401
select @includedcocosts=@includedcocosts + isnull(sum(i.FixedAmount),0),
	   @includedcounits=isnull(sum(case when i.UM=c.UM then i.Units else 0 end),0)
	   ----@includedcounits=@includedcounits + isnull(sum(i.Units),0)
from bPMOI i with (nolock) 
join bPMSC s with (nolock) on s.Status=i.Status
left join bPMDT t with (nolock) on t.DocType=i.PCOType
JOIN bJCCI c WITH (NOLOCK) ON c.JCCo=i.PMCo AND c.Contract=i.Contract AND c.Item=i.ContractItem
where i.PMCo=@cco and i.Contract=@ccontract and i.ContractItem=@citem
and isnull(i.ACOItem,'') = '' and i.FixedAmountYN = 'Y'
and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y') = 'Y'

---- get pending values from PMOI where approved and fixed
----#138401
select @includedcocosts=@includedcocosts + isnull(sum(i.ApprovedAmt),0),
	   @includedcounits=isnull(sum(case when i.UM=c.UM then i.Units else 0 end),0)
	   ----@includedcounits=@includedcounits + isnull(sum(i.Units),0)
from bPMOI i with (nolock) 
join bPMSC s with (nolock) on s.Status=i.Status
left join bPMDT t with (nolock) on t.DocType=i.PCOType
JOIN bJCCI c WITH (NOLOCK) ON c.JCCo=i.PMCo AND c.Contract=i.Contract AND c.Item=i.ContractItem
where i.PMCo=@cco and i.Contract=@ccontract and i.ContractItem=@citem
and i.ACOItem is not null
and isnull(s.IncludeInProj,'N') = 'C' and isnull(t.IncludeInProj,'Y') = 'Y' 
and not exists(select 1 from bPMOL l with (nolock) where i.PMCo = l.PMCo 
	and i.Project = l.Project and isnull(i.PCOType,'') = isnull(l.PCOType,'')
	and isnull(i.PCO,'') = isnull(l.PCO,'') and isnull(i.PCOItem,'') = isnull(l.PCOItem,'') 
	and isnull(i.ACO,'') = isnull(l.ACO,'') and isnull(i.ACOItem,'') = isnull(l.ACOItem,'') 
	and l.InterfacedDate is not null)



---- reset values
set  @crevprojunits=0
set  @crevprojdollars=0

---- Method Projected Cost Units
if isnull(@method,'')='U'
	begin
   	if @cum = 'LS' goto revcalcloop
   	
	-- Revenue Projected Units = (Cost Projected Units(JCCP.ProjUnits) \ Cost Current Estimate Units(JCCP.CurrEstUnits)) * Contract Item Current Estimated Units(JCCI.ContractUnits)
	-- Issue #129557 - needs to calculate if units are zero.
	---- if proj units <> 0 and no cost est units or item units use proj units
	if isnull(@ccostprojunits,0) <> 0 and isnull(@itemestunits,0) = 0 and isnull(@ccostestunits,0) = 0
		begin
		select @crevprojunits = isnull(@ccostprojunits,0),
	 			@crevprojdollars = isnull(@crevprojunits,0) * isnull(@cunitprice,0)
		goto JCIR_UPDATE
		end

	if isnull(@itemestunits,0) <> 0 and isnull(@ccostestunits,0) = 0 and isnull(@ccostprojunits,0) = 0 
		begin
		select @crevprojunits = isnull(@itemestunits,0),
	 			@crevprojdollars = isnull(@crevprojunits,0) * isnull(@cunitprice,0)
		goto JCIR_UPDATE
		end

	if isnull(@ccostestunits,0) = 0
		begin
			select @crevprojunits = isnull(@ccostprojunits,0),
	 				@crevprojdollars = isnull(@crevprojunits,0) * isnull(@cunitprice,0)
		end
	else
		begin
			select @crevprojunits = (isnull(@ccostprojunits,0) / isnull(@ccostestunits,0)) * @itemestunits,
	 				@crevprojdollars = isnull(@crevprojunits,0) * isnull(@cunitprice,0)
		end
   	end


-- Method Billed Units and Dollars
if isnull(@method,'')='B'
   	begin
   	select @crevprojunits=isnull(@cbilledunits,0), @crevprojdollars=isnull(@cbilleddollars,0)
   	end

-- Method Actual Cost
if isnull(@method,'')='A'
   	begin
	select @markupdollars = 0
	select @markupdollars = isnull(@cactualcost,0) * isnull(@markup,0)
	select @crevprojdollars = isnull(@cactualcost,0) + isnull(@markupdollars,0)
	   	
	if @cum <> 'LS' and isnull(@cunitprice,0) <> 0
		begin
		select @crevprojunits=isnull(@crevprojdollars,0) / isnull(@cunitprice,0)
		end
   	end

-- Method Projected Cost #123525
if isnull(@method,'')='P'
   	begin
	select @markupdollars = 0
	select @markupdollars = isnull(@revprojcost,0) * isnull(@markup,0)
	select @crevprojdollars = isnull(@revprojcost,0) + isnull(@markupdollars,0)	

	if @cum <> 'LS' and isnull(@cunitprice,0) <> 0
		begin
		select @crevprojunits=isnull(@crevprojdollars,0) / isnull(@cunitprice,0)
		end
   	end






JCIR_UPDATE:
---- add included costs and units
if isnull(@method,'') in ('P','U')
	begin
	select @crevprojunits = @crevprojunits + @includedcounits
	select @crevprojdollars = @crevprojdollars + @includedcocosts
	end

delete from dbo.bJCIR
where Co=@cco and Mth=@mth and BatchId=@batchid and Contract=@ccontract and Item = @citem

select @cplugged='N'

select @batchseq=isnull(max(BatchSeq),0)
from bJCIR with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid

insert into dbo.bJCIR (Co, Mth, BatchId, Contract, Item, ActualDate,
		RevProjUnits, RevProjDollars, PrevRevProjUnits, PrevRevProjDollars,
		RevProjPlugged, BatchSeq, Department)
select @jcco, @mth, @batchid, @ccontract, @citem, @actualdate, 
   		@crevprojunits, @crevprojdollars, @cprevrevprojunits, @cprevrevprojdollars,
		@cplugged, @batchseq + 1, @department

-- # 123525
if @crevprojdollars <> 0
	begin
		select @initcount = @initcount + 1
	end

---- next Contract Item 
goto revcalcloop


revcalcend:
select @msg = isnull(convert(varchar(5),@initcount),'') + ' revenue projections initialized.', @rcode=0




bspexit:
	---- add entry to HQ Close Control as needed
    if not exists(select 1 from dbo.bHQCC with (nolock) where Co=@jcco and Mth=@mth and BatchId=@batchid)
    	begin
    	insert into dbo.bHQCC(Co, Mth, BatchId, GLCo)
    	select @jcco, @mth, @batchid, @jcco
    	end

	if @opencursor = 1
		begin
		close bctmpRevProj
		deallocate bctmpRevProj
		set @opencursor = 0
		end
    
   return @rcode
   



   /*
   Query Used to check values from Calculation.
   declare @jcco bCompany, @mth bMonth, @bcontract bContract, @econtract bContract, 
   		@bitem bContractItem, @eitem bContractItem, @batchid int
   
   select @jcco =1, @mth ='03/01/2005', @bcontract ='    1-', @econtract ='    3-'
   select @bitem='', @eitem ='~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~', @batchid =272
   
   
   
   select p.JCCo, p.Contract, p.Item, i.UM, 
   isnull(i.UnitPrice,0) as 'Unit Price',
   isnull(sum(p.ProjUnits),0) as 'Revenue Projected Units', 
   isnull(sum(p.ProjDollars),0) as 'Revenue Projected Dollars', 
   isnull(sum(p.BilledUnits),0) as 'Billed Units',
   isnull(sum(p.BilledAmt),0) as 'Billed Amount',
   (select isnull(sum(pu.ProjUnits),0) from bJCCP pu with (nolock)
   join bJCCH ch with (nolock) on pu.JCCo=ch.JCCo and pu.Job=ch.Job and pu.Phase=ch.Phase and pu.PhaseGroup=ch.PhaseGroup and pu.CostType=ch.CostType
   join bJCJP jp with (nolock) on pu.JCCo=jp.JCCo and pu.Job=jp.Job and pu.Phase=jp.Phase and pu.PhaseGroup=jp.PhaseGroup
   where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item and pu.Mth<=@mth and
   	  ch.UM = i.UM and ch.ItemUnitFlag = 'Y') as 'Cost Projected Units',
   (select isnull(sum(c.ActualCost),0) from bJCCP c with (nolock)
   join bJCJP jp with (nolock) on c.JCCo=jp.JCCo and c.Job=jp.Job and c.Phase=jp.Phase and c.PhaseGroup=jp.PhaseGroup
   where jp.JCCo=p.JCCo and jp.Contract=p.Contract and jp.Item=p.Item and c.Mth<=@mth) as 'Actual Cost',
   i.ProjPlug
   from bJCIP p with (nolock)
   join bJCCI i with (nolock) on p.JCCo=i.JCCo and p.Contract=i.Contract and p.Item = i.Item
   join bJCCM j with (nolock) on p.JCCo=j.JCCo and p.Contract=j.Contract
   where p.JCCo=@jcco and p.Mth<=@mth and p.Contract>=@bcontract and p.Contract<=@econtract 
   and p.Item>=@bitem and p.Item<=@eitem and j.ContractStatus = 1
   and not exists(select 1 from bJCIR with (nolock) 
   				where Co=p.JCCo and Contract=p.Contract and (Mth<>@mth or (BatchId <> @batchid and Mth = @mth)))
   Group by p.JCCo, p.Contract, p.Item, i.UM, i.UnitPrice, i.ProjPlug
   */

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjCalc] TO [public]
GO
