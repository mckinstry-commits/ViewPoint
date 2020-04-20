SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMCOItemInitFill]
/****************************************************************************
 * Created By:	GF 11/13/2002
 * Modified By:	GF 05/13/2003 - added original and current contract item amounts to resultset
 *				GF 01/12/2005 - issue #22097 calculate units/dollars based on difference 
 *								between current estimated and current billed in JB.
 *				GF 02/07/2005 - issue #22097 added JBIT non-interfaced bill units and amount.
 *				GF 10/30/2008 - issue #130772 expanded description to 60 characters
 *
 *
 * USAGE:
 * 	Fills grid with contract items to populate grid for CO item initialize.
 *	PMChgOrderItemInit form
 *
 * INPUT PARAMETERS:
 *   PM Company, Project, PCOType, PCO, ACO, Contract, BegItem, EndItem,
 *	DefaultDesc, DefaultFixed, DefaultGenerate, StartMonth, BillGroup,
 *	IncludeLumpSum, CalculateAddlUnits, PositiveUnitsOnly
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany = null, @project bJob = null, @contract bContract = null, @defaultdesc bYN = 'Y',
 @defaultfixed bYN = 'N', @defaultgenerate bYN = 'N', @pcotype bPCOType = null, @pco bPCO = null,
 @aco bACO = null, @begitem bContractItem = null, @enditem bContractItem = null, @startmonth bMonth = null,
 @billgroup bBillingGroup = null, @includels bYN = 'N', @calcunits bYN = 'N', @positiveunitsonly bYN = 'N',
 @thrumonth bMonth = null, @userid bVPUserName = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor int, @codesc bItemDesc, @maxitem int, 
		@coitem bPCOItem, @inputmask varchar(30), @item bContractItem,
   		@currestunits bUnits, @currestamt bDollar, @currbillunits bUnits, @currbillamt bDollar,
   		@um bUM, @unitprice bUnitCost, @openbillunit bUnits, @openbillamt bDollar, 
   		@addlunits bUnits, @addlamt bDollar


select @rcode = 0, @retcode = 0, @opencursor = 0

if isnull(@pcotype,'') = '' select @defaultfixed = 'N'

if isnull(@defaultfixed,'') = '' select @defaultfixed = 'N'
if isnull(@defaultgenerate,'') = '' select @defaultgenerate = 'N'

-- get input mask for bPCOItem
select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPCOItem'

if isnull(@pcotype,'') = ''
	begin
	select @codesc = Description from PMOH with (nolock)
	where PMCo=@pmco and Project=@project and ACO=@aco
	select @maxitem = isnull(max(ACOItem),0) from PMOI with (nolock)
	where PMCo=@pmco and Project=@project and ACO=@aco
	and PatIndex('%[^0-9]%',ltrim(rtrim(ACOItem))) = 0
	end
else
	begin
	select @codesc = Description from PMOP with (nolock)
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
	select @maxitem = isnull(max(PCOItem),0) from PMOI with (nolock)
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
	and PatIndex('%[^0-9]%',ltrim(rtrim(PCOItem))) = 0
	end




-- -- -- created temporary table to store CO items
create table #COItemInit
(
    	Item			varchar(16)		not null,
    	COItem			varchar(10)		null,
    	Description		varchar(60)		null,
    	OrigUnits		numeric(12,3)	not null,
    	OrigAmt			numeric(12,2)	not null,
    	CurrUnits		numeric(12,3)	not null,
    	CurrAmt			numeric(12,2)	not null,
    	CurrBillUnits	numeric(12,3)	not null,
    	CurrBillAmt		numeric(12,2)	not null,
    	ProjUnits		numeric(12,3)	not null,
    	AddlUnits		numeric(12,3)	not null,
    	UM				varchar(3)		not null,
    	UnitPrice		numeric(16,5)	not null,
    	Amount			numeric(12,2)	not null,
   		JBITBillUnits	numeric(12,3)	not null,
   		JBITBillAmt		numeric(12,2)	not null,
    	Fixed			char(1)			not null,
    	Generate		char(1)			not null
)


-- -- -- insert contract items from JCCI into temp table
insert into #COItemInit
select a.Item, Null, case @defaultdesc when 'N' then @codesc else a.Description end,
    		isnull(a.OrigContractUnits,0), isnull(a.OrigContractAmt,0), 
    		isnull(a.ContractUnits,0), isnull(a.ContractAmt,0),
    		isnull(sum(b.BilledUnits),0), isnull(sum(b.BilledAmt),0),
    		isnull(a.ContractUnits,0), 0, isnull(a.UM,'LS'),
    		isnull(a.UnitPrice,0), 0, 0, 0, @defaultfixed, @defaultgenerate
from JCCI a with (nolock) 
left join JCIP b with (nolock) on b.JCCo=a.JCCo and b.Contract=a.Contract and b.Item=a.Item
where a.JCCo=@pmco and a.Contract=@contract and a.Item is not null
and a.Item >= isnull(@begitem,a.Item) and a.Item <= isnull(@enditem,a.Item)
and isnull(a.BillGroup,'') = coalesce(@billgroup,a.BillGroup,'')
and isnull(a.StartMonth,'') = coalesce(@startmonth,a.StartMonth,'')
Group By a.Item, a.Description, a.OrigContractUnits, a.OrigContractAmt, a.ContractUnits, a.ContractAmt, a.UM, a.UnitPrice

-- -- -- remove 'LS' contract items if needed
if isnull(@includels, 'N') = 'N'
	begin
	delete from #COItemInit
	where #COItemInit.UM = 'LS'
	end

-- -- -- set fixed flag to 'Y' when PCO and UM = 'LS'
if isnull(@pcotype,'') <> ''
	begin
	update #COItemInit set Fixed = 'Y'
	where #COItemInit.UM = 'LS'
	end


-- -- -- if @calculate additional units = 'Y' then calculate additional units or dollars (LS)
-- -- -- for each Item in the #COItemInit table. Current Billed + Open Bills - Current Estimate
-- -- -- declare cursor on PMOL for PCO/ACO item to get and load units, hours, costs from JCCD
if isnull(@calcunits,'N') = 'N' goto PMOZ_Insert

declare bcPMCOItemInit cursor for select Item, CurrUnits, CurrAmt, CurrBillUnits, CurrBillAmt, UnitPrice, UM
from #COItemInit

-- -- -- open cursor
open bcPMCOItemInit
set @opencursor = 1

PMCOItemInit_loop:
fetch next from bcPMCOItemInit into @item, @currestunits, @currestamt, @currbillunits, @currbillamt, @unitprice, @um   
if @@fetch_status <> 0 goto PMCOItemInit_end

select @openbillunit = 0, @openbillamt = 0, @addlunits = 0, @addlamt = 0
-- -- -- check for open bills for the contract item
select @openbillunit = sum(b.UnitsBilled), @openbillamt=sum(b.AmtBilled)
from bJBIT b where b.JBCo=@pmco and b.Contract=@contract and b.Item = @item 
and b.BillMonth <= isnull(@thrumonth, b.BillMonth)
and exists(select * from bJBIN a where a.JBCo=b.JBCo and a.BillMonth=b.BillMonth and a.BillNumber=b.BillNumber and a.InvStatus='A')

-- -- -- update non-interfaced bill values
if @um = 'LS'
   	begin
   	update #COItemInit set JBITBillAmt = isnull(@openbillamt,0)
   	where #COItemInit.Item = @item
   	end
else
   	begin
   	update #COItemInit set JBITBillUnits = isnull(@openbillunit,0), JBITBillAmt = isnull(@openbillamt,0)
   	where #COItemInit.Item = @item
   	end

-- -- -- calculate addl units and amt
set @addlunits = (@currbillunits + isnull(@openbillunit,0)) - @currestunits
set @addlamt = (@currbillamt + isnull(@openbillamt,0)) - @currestamt

-- -- -- anything to process???
if @addlunits = 0 and @addlamt = 0 goto PMCOItemInit_loop

-- -- -- check if values are negative and @positiveunitsonly = 'Y'
if isnull(@positiveunitsonly,'Y') = 'Y'
   	begin
   	if @um <> 'LS' and @addlunits <= 0 goto PMCOItemInit_loop
   	if @um = 'LS' and @addlamt <= 0 goto PMCOItemInit_loop
   	end
   
if @um = 'LS'
   	begin
   	update #COItemInit set Amount = @addlamt
   	where #COItemInit.Item = @item
   	end
else
   	begin
   	update #COItemInit set AddlUnits = @addlunits, Amount = @addlunits * @unitprice
   	where #COItemInit.Item = @item
   	end


-- -- -- next item
goto PMCOItemInit_loop


PMCOItemInit_end:
	if @opencursor = 1
		begin
		close bcPMCOItemInit
		deallocate bcPMCOItemInit
		set @opencursor = 0
		end




PMOZ_Insert:

-- -- -- populate PMOZ with rows from #COItemInit
insert into bPMOZ (UserId,ContractItem,PMCo,Contract,Description,COItem,OrigUnits,OrigAmt,CurrUnits,CurrAmt,
		CurrBillAmt,CurrBillUnits,ProjUnits,AddlUnits,UM,UnitPrice,Amount,JBITBillAmt,JBITBillUnits,Fixed,Generate)
select @userid, a.Item, @pmco, @contract, a.Description, a.COItem, a.OrigUnits, a.OrigAmt, a.CurrUnits, a.CurrAmt,
		a.CurrBillAmt, a.CurrBillUnits, a.ProjUnits, a.AddlUnits, a.UM, a.UnitPrice, a.Amount, a.JBITBillAmt, a.JBITBillUnits,
		isnull(a.Fixed,'N'), isnull(a.Generate,'N')
from #COItemInit a 






bspexit:
	if @opencursor = 1
		begin
		close bcPMCOItemInit
		deallocate bcPMCOItemInit
		set @opencursor = 0
		end

	drop table #COItemInit
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemInitFill] TO [public]
GO
