SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadPCOVal	Script Date: 06/07/2006 ******/
CREATE proc [dbo].[vspPMImportUploadPCOVal]
/***********************************************************
 * Created By:	GF 06/07/2006 6.x issue #
 * Modified By:	GF 10/30/2008 - issue #130772 expanded PCO desc and PCO item desc to 60 characters
 *
 *
 *
 * USAGE:
 * Validates PM PCO for PM import upload form.
 *
 *
 *
 * INPUT PARAMETERS
 * PMCO			PM Company 
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO to validate
 *
 *
 *
 * OUTPUT PARAMETERS
 * Exists			PM PCO exists flag
 * Approved			PM PCO code exists as approved
 * PCO Desc			PM PCO Description
 * dup_items_exist	flag to indicate if duplicate items exists on PCO for contract items
 * next item		next sequential numberic pco item from PMOI
 * format_coitem	formatted co item for the contract item
 * format_coitem_desc	formatted co item description from PMWI
 *
 *
 * @msg - error message if error occurs otherwise Description of PCO in PMOP
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/ 
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null,
 @pco varchar(10) = null, @importid varchar(10) = null, 
 @exists bYN = 'Y' output, @approved bYN = 'N' output, @pco_desc bItemDesc = null output,
 @dup_items_exist bYN = 'N' output, @nextitem int = 0 output, @format_coitem varchar(10) = null output,
 @format_coitem_desc bItemDesc = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor int, @pmwi_item bContractItem, @inputmask varchar(30),
		@itemlength varchar(10), @item varchar(10), @pcoitem bPCOItem, @maxitem bPCOItem,
		@pmwi_desc bItemDesc

select @rcode = 0, @opencursor = 0, @exists = 'Y', @approved = 'N', @dup_items_exist = 'N', @nextitem = 0,
		@format_coitem = null

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

if @pcotype is null
   	begin
   	select @msg = 'Missing PCO Type!', @rcode = 1
   	goto bspexit
   	end

if @pco is null
   	begin
   	select @msg = 'Missing PCO!', @rcode = 1
   	goto bspexit
   	end

------ get the mask for bPCOItem
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end



------ see if the PCO exists for project as an ACO
if exists(select * from PMOH with (nolock) where PMCo=@pmco and Project=@project and ACO=@pco)
	begin
	select @approved = 'Y'
	end

------ validate PCO to PMOP
select @msg=Description, @pco_desc=Description
from PMOP with (nolock) where PMCo = @pmco and Project = @project and PCOType=@pcotype and PCO=@pco
if @@rowcount = 0 
   	begin
	select @exists = 'N'
   	select @msg = 'New PCO'
	----goto bspexit
   	end

------ try to get the max numeric CO item + 1 for default starting item
select @maxitem = isnull(max(PCOItem),0)
from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
and PCO=@pco and isnumeric(PCOItem) = 1 and PCOItem not like '%.%'
if @@rowcount = 0 select @maxitem = '0'
if @maxitem is null select @maxitem = '0'
select @nextitem = convert(int,@maxitem) + 1

------ check for duplicate contract items that exist as CO items in PMOI for the PCO
------ declare cursor for PMWI on Import Id for items, format to CO item datatype
------ and verify if exists. Only need one to exist to invalidate using contract items 
------ as CO items.
declare bcPMWI cursor LOCAL FAST_FORWARD
for select Item, Description
from PMWI with (nolock) where PMCo=@pmco and ImportId=@importid

-- -- -- open cursor
open bcPMWI
select @opencursor = 1

-- -- -- loop through PMWI
PMWI_loop:
fetch next from bcPMWI into @pmwi_item, @pmwi_desc

if (@@fetch_status <> 0) goto PMWI_end

------ item must be 10 characters or less to format as an CO Item.
if datalength(ltrim(rtrim(@pmwi_item))) > 10 goto PMWI_loop

------ format @pmwi_item to bPCOItem
select @item = ltrim(rtrim(@pmwi_item))
select @pcoitem = null
exec @retcode = dbo.bspHQFormatMultiPart @item, @inputmask, @pcoitem output
if @retcode <> 0 goto PMWI_loop

------ check if formatted @pcoitem exists in PMOI for the PCO
if exists(select * from PMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype
			and PCO=@pco and PCOItem=@pcoitem)
	begin
	select @dup_items_exist = 'Y'
	goto PMWI_end
	end


select @format_coitem = @pcoitem
select @format_coitem_desc = @pmwi_desc
goto PMWI_loop



PMWI_end:
	if @opencursor = 1
		begin
		close bcPMWI
		deallocate bcPMWI
  		select @opencursor = 0
  		end













bspexit:
	if @opencursor = 1
		begin
		close bcPMWI
		deallocate bcPMWI
  		select @opencursor = 0
  		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadPCOVal] TO [public]
GO
