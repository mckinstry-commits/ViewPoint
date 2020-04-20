SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOItemGet    Script Date: 8/28/99 9:35:16 AM ******/
CREATE proc [dbo].[bspPMPCOItemGet]
/***********************************************************
 * CREATED BY: GF 10/23/98
 * MODIFED BY: GF 04/28/2000
 *				GF 12/11/2006 - 6.x added forcephase and changedays output params
 *				GF 04/30/2008 - issue #22100 redirect addon revenue
 *				GF 10/30/2008 - issue #130772 expanded desc to 60 characters.
 *				GF 02/10/2008 - issue #129669 calculate add-ons before assigning to aco.
 *
 *
 *
 * this proc is used for ACOs to get the default info if from a PCO.
 *
 * USAGE:
 *   Validates PM Pending Change Order Item
 *   An error is returned if any of the following occurs
 * 	no company passed
 *	no project passed
 *      no PCO passed
 *      no PCO Item passed
 *	no matching PCO Item found in PMOI
 *
 * INPUT PARAMETERS
 *   PMCO- JC Company to validate against
 *   PROJECT- project to validate against
 *   PCO - Pending Change Order to validate
 *   PCOItem - PCO Item to validate
 *
 * OUTPUT PARAMETERS
 * Contractitem
 * Units
 * UM
 * UnitPrice
 * Amount
 * Description
 * Force Phase Flag
 * Change in Days
 * AddOnAmt to redirect
 * @msg - error message if error occurs otherwise Description of PCOItem in PMOI
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null, @pco varchar(10) = null,
 @pcoitem bPCOItem = null, @aco bACO = null, @acoitem bACOItem = null,
 @contractitem bContractItem = null output, @units bUnits = null output,
 @um bUM = null output, @unitprice bUnitCost = null output, @amount bDollar = null output,
 @description bItemDesc = null output, @forcephase bYN output, @changedays smallint output, 
 @addonamt bDollar = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @retmsg varchar(150), @testaco bACO, @testacoitem bACOItem,
   		@curpendingamount bDollar, @curfixedamount bDollar, @curfixedamountyn bYN,
		@intext char(1)

select @rcode = 0, @forcephase = 'N', @changedays = 0, @addonamt = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @pco is null
   	begin
   	select @msg = 'Missing PCO!', @rcode = 1
   	goto bspexit
   	end

if @pcotype is null
   	begin
   	select @msg = 'Missing PCO Type!', @rcode = 1
   	goto bspexit
   	end

if @pcoitem is null
   	begin
   	select @msg = 'Missing PCO Item!', @rcode = 1
   	goto bspexit
   	end

---- check if pco/item approval possible
exec @retcode = bspPMPCOApprovalCheck @pmco, @project, @pcotype, @pco, @pcoitem, @retmsg output
if @retcode <> 0
	begin
	select @msg = @retmsg, @rcode = 1
	goto bspexit
	end

---- first run add-on calculations so that distribution phase cost types are ready to go
exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem

---- get PCO item info from PMOI
select @description=Description, @testaco=ACO, @testacoitem=ACOItem, @contractitem=ContractItem,
		@units=Units, @um=UM, @unitprice=UnitPrice, @curpendingamount=PendingAmount,
		@curfixedamount=FixedAmount, @curfixedamountyn=FixedAmountYN, @forcephase=ForcePhaseYN,
		@changedays=ChangeDays
from bPMOI with (nolock) where PMCo = @pmco and Project = @project and PCOType=@pcotype
and PCO=@pco and PCOItem=@pcoitem
if @@rowcount = 0
	begin
   	select @msg = 'PCO Item not on file!', @rcode = 1
   	goto bspexit
   	end

---- see if already approved to another change order item
if isnull(@testaco,'') <> '' and (@testaco <> @aco or @testacoitem <> @acoitem)
	begin
   	select @msg = 'Item already assigned to another Approved Change Order Item!', @rcode = 1
   	goto bspexit
   	end

---- if fixed use fixed amount
if @curfixedamountyn <> 'N'
   	begin
   	select @amount=@curfixedamount
   	end

---- if not fixed use pending amount
if @curfixedamountyn = 'N'
   	begin
   	select @amount=@curpendingamount
   	if @units = 0 or @um = 'LS'
		begin
		select @unitprice=0
		end
   	else
		begin
		select @unitprice = @curpendingamount/@units
		end
	end

---- check @unitprice
if @unitprice is null
	begin
	select @unitprice = 0
	end

---- check @amount
if @amount is null
   	begin
   	select @amount = 0
   	end

---- get PMOA addon amount that will be redirect to a different ACO item when ACO item is added
select @addonamt = isnull(sum(a.AddOnAmount),0)
from bPMOA a with (nolock)
join bPMPA b on b.PMCo=a.PMCo and b.Project=a.Project and b.AddOn=a.AddOn
where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pcotype and a.PCO=@pco
and a.PCOItem=@pcoitem and b.RevRedirect = 'Y'

---- get PMOP.IntExt flag
select @intext=IntExt from bPMOP with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
if isnull(@intext,'') = '' select @intext='E'

---- if internal change order exit
if @intext = 'I' goto bspexit
---- if fixed amount exit
if @curfixedamountyn = 'Y' goto bspexit
---- if no addon revenue to redirect exit
if @addonamt = 0 goto bspexit

---- adjust the unit price and amount to reflect the addon revenue
---- being redirect to another item
select @amount = isnull(@amount,0) - isnull(@addonamt,0)
if @units <> 0 and @um <> 'LS'
	begin
	select @unitprice = @amount/@units
	end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOItemGet] TO [public]
GO
