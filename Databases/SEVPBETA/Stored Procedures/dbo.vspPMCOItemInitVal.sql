SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************************/
CREATE  proc [dbo].[vspPMCOItemInitVal]
/***********************************************************
 * Created By:	GF 01/17/2006
 * Modified By:
 *
 *
 *
 *
 * USAGE:
 * Validates PM Pending Change Order Item or Approved Change
 * Order Item. Used in PMChgOrderItemsInit to verify uniqueness.
 * If the @coitem is '+' then program will try to get the next
 * sequential integer co item number.
 *
 *
 *
 * INPUT PARAMETERS
 * PMCO - JC Company
 * PROJECT - Project
 * PCOType - PCO type
 * PCO - Pending Change Order
 * PCOItem - PCO Item
 * ACO		- Approved Change Order
 * COItem	- ACO/PCO Item
 * UserId		VP User Name
 * Contract		Contract
 *
 *
 *
 * OUTPUT PARAMETERS
 * @new_coitem		returns next co item available if possible
 * @msg - error message if error occurs
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType =null, @pco bPCO = null,
 @aco bACO = null, @coitem bPCOItem = null, @userid bVPUserName = null, 
 @contract bContract = null, @c_item bContractItem = null, 
 @new_coitem bPCOItem = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @contractitem bContractItem, @pmoi_item bPCOItem, @pmoz_item bPCOItem,
		@lastcoitem int, @next_item int, @item bContractItem, @seq_item varchar(20), 
		@inputmask varchar(30), @itemlength varchar(10)

select @rcode = 0

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

if @coitem is null
   	begin
   	select @msg = 'Missing CO Item!', @rcode = 1
   	goto bspexit
   	end

if @pcotype is null
   	begin
   	select @pco = null
   	-- -- -- check ACO
   	if @aco is null
   		begin
   		select @msg = 'Missing ACO!', @rcode = 1
   		goto bspexit
   		end
   	end
else
   	begin
   	select @aco = null
   	-- check PCO
   	if @pco is null
   		begin
   		select @msg = 'Missing PCO!', @rcode = 1
   		goto bspexit
   		end
   	end

-- -- -- get input mask for bPCOItem
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end

-- -- -- get the maximum co item from PMOI for aco or pco when @coitem = '+'
if ltrim(@coitem) = '+'
	begin
	-- -- -- for PCO's get max numeric PCO item from PMOI for the PCOType and PCO
	if isnull(@pcotype,'') = ''
	   	begin
	   	select @pmoi_item = max(ACOItem)
	   	from bPMOI where PMCo=@pmco and Project=@project and ACO=@aco 
	   	and isnumeric(ACOItem) = 1 and ACOItem not like '%.%'
	   	select @lastcoitem = convert(int, isnull(@pmoi_item, '0'))
	   	end
	else
	   	begin
	   	select @pmoi_item = max(PCOItem)
	   	from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco 
	   	and isnumeric(PCOItem) = 1 and PCOItem not like '%.%'
	   	select @lastcoitem = convert(int, isnull(@pmoi_item, '0'))
	   	end
	
	if isnull(@lastcoitem,0) = 0 select @lastcoitem = 0

	-- -- -- get max(COItem) from PMOZ
	select @pmoz_item = max(COItem)
	from PMOZ where UserId=@userid and isnumeric(COItem) = 1 and COItem not like '%.%'
	if isnull(@pmoz_item,0) = 0 select @pmoz_item = 0
	
	-- -- -- use higher of PMOI or PMOZ item
	if @lastcoitem <= @pmoz_item
		select @next_item = @pmoz_item
	else
		select @next_item = @lastcoitem
	
	-- -- -- format item to spec
	select @seq_item = convert(varchar(10), @next_item + 1)
	exec @rcode = dbo.bspHQFormatMultiPart @seq_item, @inputmask, @new_coitem output
	if @rcode <> 0 select @new_coitem = null
	select @rcode = 0
	goto bspexit
	end








-- -- -- verify that the CO item does not already exist
if @pcotype is null
   	begin
   	select @msg = Description
   	from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@coitem
   	if @@rowcount <> 0
   		begin
   		select @msg = 'ACO Item already exists!', @rcode = 1
   		goto bspexit
   		end
   	end
else
   	begin
   	select @msg = Description
   	from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@coitem
   	if @@rowcount <> 0
   		begin
   		select @msg = 'PCO Item already exists!', @rcode = 1
   		goto bspexit
   		end
   	end


------ verify that the CO item does not already exists in PMOZ
select @msg = Description, @contractitem=ContractItem
from PMOZ where UserId=@userid and Contract=@contract and PMCo=@pmco and COItem=@coitem and ContractItem<>@c_item
if @@rowcount <> 0
	begin
	select @msg = isnull(@userid,'') + '/' + isnull(@contract,'') + '/' + convert(varchar(3),@pmco) + '/' + isnull(@coitem,'') + '/' + isnull(@c_item,''), @rcode = 1
	--select @msg = 'The CO Item entered currently exists for contract item ' + isnull(@contractitem,'') + ', duplicates not allowed', @rcode = 1
	goto bspexit
	end





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemInitVal] TO [public]
GO
