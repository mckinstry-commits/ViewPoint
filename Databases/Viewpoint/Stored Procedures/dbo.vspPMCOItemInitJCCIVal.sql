SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMCOItemInitJCCIVal]
/****************************************************************************
 * Created By:	GF 01/16/2005
 * Modified By:
 *
 *
 *
 *
 *
 * USAGE:
 * validates contract item manually entered in PMChgOrdItemsInit form. Contract Item
 * must not already exists, and returns information needed to initialize a
 * change order item.
 *
 *
 * INPUT PARAMETERS:
 * PMCo, Project, UserId, PCOType, PCO, ACO, Contract, ContractItem
 *
 *
 * OUTPUT PARAMETERS:
 * OrigUnits, OrigAmt, CurrUnits, CurrAmt, CurrBillUnits, CurrBillAmt, @unitprice,
 * UM, ProjUnits, JBITBillUnits, JBITBillAmt, AddlUnits, AddlAmt
 *
 * RETURN VALUE:
 * 	0 	    Success and description from JCCI
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany = null, @project bJob = null, @userid bVPUserName = null, @pcotype bPCOType = null,
 @pco bPCO = null, @aco bACO = null, @contract bContract = null, @contractitem bContractItem = null,
 @origunits bUnits = 0 output, @origamt bDollar = 0 output, @currunits bUnits = 0 output,
 @curramt bDollar = 0 output, @currbillunits bUnits = 0 output, @currbillamt bDollar = 0 output,
 @unitprice bUnitCost = 0 output, @um bUM = null output, @projunits bUnits = 0 output,
 @jbitbillunits bUnits = 0 output, @jbitbillamt bDollar = 0 output, @addlunits bUnits = 0 output,
 @addlamt bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @pmco is null or @project is null or @userid is null or @contract is null
	begin
	select @msg = 'Missing key fields, cannot add contract item.', @rcode = 1
	goto bspexit
	end


-- -- -- validate JCCI get item data
select @msg=Description, @origunits=OrigContractUnits, @origamt=OrigContractAmt,
		@currunits=ContractUnits, @curramt=ContractAmt, @um=UM, @unitprice=UnitPrice,
		@projunits=ContractUnits
from JCCI with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
if @@rowcount = 0
	begin
	select @msg = 'Invalid contract item.', @rcode = 1
	goto bspexit
	end

-- -- -- get current billed from JCIP
select @currbillunits=sum(BilledUnits), @currbillamt=sum(BilledAmt)
from JCIP with (nolock) where JCCo=@pmco and Contract=@contract and Item=@contractitem
if @currbillunits is null select @currbillunits = 0
if @currbillamt is null select @currbillamt = 0

-- -- -- get open bill units and amount
select @jbitbillunits = 0, @jbitbillamt = 0, @addlunits = 0, @addlamt = 0
-- -- -- check for open bills for the contract item
select @jbitbillunits = sum(b.UnitsBilled), @jbitbillamt=sum(b.AmtBilled)
from bJBIT b where b.JBCo=@pmco and b.Contract=@contract and b.Item=@contractitem 
and exists(select * from bJBIN a where a.JBCo=b.JBCo and a.BillMonth=b.BillMonth and a.BillNumber=b.BillNumber and a.InvStatus='A')
if @jbitbillunits is null select @jbitbillunits = 0
if @jbitbillamt is null select @jbitbillamt = 0

-- -- -- if @um='LS' then set open bill units to zero
if @um = 'LS' select @jbitbillunits = 0

-- -- -- calculate addl units and amt
select @addlunits = (@currbillunits + isnull(@jbitbillunits,0)) - @currunits
select @addlamt = (@currbillamt + isnull(@jbitbillamt,0)) - @curramt

-- -- -- if @um='LS' then set additional units to zero
if @um = 'LS' select @addlunits = 0



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemInitJCCIVal] TO [public]
GO
