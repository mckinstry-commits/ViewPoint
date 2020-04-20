SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOApproveItemVal    Script Date: 8/28/99 9:33:04 AM ******/ 
CREATE proc [dbo].[bspPMPCOApproveItemVal]
/***********************************************************
* CREATED BY:	bc 6/26/98
* Modified By: GF 07/24/2000
*				TV 03/30/01
*				GF 12/09/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 04/30/2008 - issue #22100 redirect addon revenue
*				GF 07/10/2008 - issue #128935 changed isnull wrapper for addon amount
*				GF 10/30/2008 - issue #130772 expanded desc to 60 characters.
*
*
*
* USAGE:
*   Validates PM Pending Change Order Item
*   An error is returned if any of the following occurs
*   no company passed
*	  no project passed
*	  no matching ACO found in PMOH
*   no item passed
*   ACO Item already set up
*
* INPUT PARAMETERS
*   PMCO- JC Company to validate against
*   PROJECT- project to validate against
*   PCO - Passed Pending change order needed to default values from PMOP on new ACOs and to make error checks.
*   ACO - New user input for pending PCO
*   PCOType - PCO type needed to default values from PMOP on new ACOs
*   PCOItem - Item from parent form.  Used for default and error handling purposes.
*   ACOItem - New user input for the Pending PCOItem
*
* OUTPUT PARAMETERS
*	@desc - description
* @approval_amt - amount approved for this item.
*	@contract - needed for contract item validation in JCCI
*	@contract_item - The contract item the CO item affects
* @units - # of units approved for this CO Item
* @um - units of measure of the approved units
* @changedays - Change in Days from PMOI
* @msg - error message if error occurs
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pco bPCO = null, @aco bPCO = null,
 @pco_type bDocType = null, @pco_item bPCOItem = null, @aco_item bPCOItem = null,
 @desc varchar(60) output, @approval_amt bDollar output, @contract bContract output,
 @contract_item bContractItem output, @units bUnits output, @um bUM output,
 @changedays smallint output, @addonamt bDollar = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @count int, @err_aco bPCO, @fixedyn bYN, @fixedamt bDollar,
		@pendingamt bDollar, @intext char(1)

select @rcode = 0, @approval_amt = 0, @fixedyn = 'N', @fixedamt = 0, @pendingamt = 0

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

if @aco is null
	begin
	select @msg = 'Missing PCO!', @rcode = 1
	goto bspexit
	end

if @aco_item is null
	begin
	select @msg = 'Missing PCO Item!', @rcode = 1
	goto bspexit
	end

---- Make sure that the input item # does not exist for this ACO
select @msg = ACOItem from bPMOI with (nolock)
where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@aco_item
if @@rowcount <> 0
	begin
	select @msg = 'Item ' + isnull(@msg,'') + ' already exists in Change Order ' + isnull(@aco,''), @rcode = 1
	goto bspexit
	end

---- now make sure this PCOItem has not been approved before
select @err_aco = ACO from bPMOI with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
and PCOItem=@pco_item and Approved='Y'
if @@rowcount <> 0
	begin
	select @msg = 'The original pending item has already been approved on change order: ' + isnull(@err_aco,''), @rcode =1
	goto bspexit
	end

---- get defaults from the PMOI pending values
select @desc=Description, @fixedyn=FixedAmountYN, @contract=Contract, @contract_item=ContractItem,
		@units=Units, @um=UM, @fixedamt=FixedAmount, @pendingamt=PendingAmount, @approval_amt=PendingAmount,
		@changedays = ChangeDays
from bPMOI with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and PCOItem=@pco_item
if @@rowcount <> 0 and @fixedyn = 'Y' select @approval_amt = @fixedamt


---- get PMOA addon amount that will be redirect to a different ACO item when ACO item is added
select @addonamt = isnull(sum(a.AddOnAmount),0) ---- #128935
from bPMOA a with (nolock)
join bPMPA b on b.PMCo=a.PMCo and b.Project=a.Project and b.AddOn=a.AddOn
where a.PMCo=@pmco and a.Project=@project and a.PCOType=@pco_type and a.PCO=@pco
and a.PCOItem=@pco_item and b.RevRedirect = 'Y'

---- get PMOP.IntExt flag
select @intext=IntExt from bPMOP with (nolock)
where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
if isnull(@intext,'') = '' select @intext='E'

---- if internal change order exit
if @intext = 'I' goto bspexit
---- if fixed amount exit
if @fixedyn = 'Y' goto bspexit
---- if no addon revenue to redirect exit
if @addonamt = 0 goto bspexit

---- adjust the unit price and amount to reflect the addon revenue
---- being redirect to another item
select @approval_amt = @approval_amt - @addonamt
----if @units <> 0 and @um <> 'LS'
----	begin
----	select @unitprice = @amount/@units
----	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApproveItemVal] TO [public]
GO
