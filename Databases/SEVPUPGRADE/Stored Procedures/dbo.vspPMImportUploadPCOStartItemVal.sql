SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadPCOStartItemVal ******/
CREATE proc [dbo].[vspPMImportUploadPCOStartItemVal]
/***********************************************************
 * Created By:	GF 12/04/2006 6.x issue #27450
 * Modified By:
 *
 *
 * USAGE:
 * Validates PM PCO Starting item and increment by values as unique
 * for the PCOType and PCO. Called from PM import upload form.
 *
 *
 *
 * INPUT PARAMETERS
 * PMCO				PM Company 
 * Project			PM Project
 * PCOType			PM PCO Type
 * PCO				PM PCO
 * StartingItem		Starting numeric PCO item
 * IncrementBy		Increment by value
 * ImportId			PM Import Id
 *
 *
 *
 * OUTPUT PARAMETERS
 *
 *
 *
 * @msg - error message if error occurs otherwise
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/ 
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null,
 @pco varchar(10) = null, @start_item int, @increment_by int, 
 @importid varchar(10), @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor int, @pmwi_count int, @inputmask varchar(30),
		@itemlength varchar(10), @item varchar(10), @pcoitem bPCOItem, @increment_count int,
		@next_item int

select @rcode = 0, @opencursor = 0, @pmwi_count = 0, @increment_count = 0

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

if @start_item is null
	begin
	select @msg = 'Missing starting PCO item.', @rcode = 1
	goto bspexit
	end

if @increment_by is null
	begin
	select @msg = 'Missing increment by value.', @rcode = 1
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

---- get count of contract items in PMWI
select @pmwi_count = count(*) from PMWI with (nolock)
where PMCo=@pmco and ImportId=@importid
if @pmwi_count = 0
	begin
	select @msg = 'No contract items in PMWI, at least one is required.', @rcode = 1
	goto bspexit
	end


---- beginning with start item check for duplicates in PMOI
select @increment_count = 1
while @increment_count <= @pmwi_count
BEGIN
	if @increment_count = 1
		begin
		select @item = convert(varchar(10),@start_item)
		end
	else
		begin
		select @item = convert(varchar(10),@next_item)
		end

	---- format @item as PCO item
	select @pcoitem = null
	exec @retcode = dbo.bspHQFormatMultiPart @item, @inputmask, @pcoitem output
	---- check if formatted @pcoitem exists in PMOI for the PCO
	if exists(select * from PMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype
			and PCO=@pco and PCOItem=@pcoitem)
		begin
		select @msg = 'Found a duplicate PCO Item using starting item and increment by. PCO Item must be unique.', @rcode = 1
		goto bspexit
		end

	---- increment and set next item value
   	select @increment_count = @increment_count + 1
	select @next_item = convert(int,@item) + @increment_by
END











bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadPCOStartItemVal] TO [public]
GO
