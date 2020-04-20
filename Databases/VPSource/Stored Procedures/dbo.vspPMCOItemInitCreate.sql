SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMCOItemInitCreate]
/****************************************************************************
 * Created By:	GF 02/15/2006 for 6.x
 * Modified By:
 *
 *
 *
 *
 * USAGE:
 * Cycles through PMOZ records for user and creates a CO item if none exists.
 * Called from PMChgOrderItemInit form
 *
 * INPUT PARAMETERS:
 * PM Company, Project, Contract, PCOType, PCO, ACO, UserId
 *
 *
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany = null, @project bJob = null, @pcotype bPCOType = null,
 @pco bPCO = null, @aco bACO = null, @userid bVPUserName = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @opencursor int, @pmoi_item bPCOItem, @pmoz_item bPCOItem,
		@lastcoitem int, @next_item int, @item bContractItem, @coitem bPCOItem,
		@seq_item varchar(20), @inputmask varchar(30), @itemlength varchar(10),
   		@um bUM, @addlunits bUnits, @amount bDollar


select @rcode = 0, @opencursor = 0, @lastcoitem = 0


------ first check to see if there are any PMOZ records for user that do not have a CO Item.
if not exists(select top 1 1 from PMOZ with (nolock) where UserId = @userid and COItem is null)
	begin
	------select @msg = 'No contract items to create CO items for.', @rcode = 1
	goto bspexit
	end

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

-- -- -- get input mask for bPCOItem
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end


-- -- -- declare cursor on PMOZ for UserId and COItem is null
declare bcPMOZ cursor for select ContractItem, COItem, UM, AddlUnits, Amount
from PMOZ
where UserId = @userid and isnull(COItem,'') = ''

-- -- -- open cursor
open bcPMOZ
set @opencursor = 1

PMOZ_loop:
fetch next from bcPMOZ into @item, @coitem, @um, @addlunits, @amount
if @@fetch_status <> 0 goto PMOZ_end

-- -- -- if co item exists goto next
if isnull(@coitem,'') <> '' goto PMOZ_loop
-- -- -- if @um <> 'LS' and @addlunits = 0 goto next
if @um <> 'LS' and @addlunits = 0 goto PMOZ_loop
-- -- -- if @um = 'LS' and @amount = 0 goto next
if @um = 'LS' and @amount = 0 goto PMOZ_loop

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
exec @rcode = dbo.bspHQFormatMultiPart @seq_item, @inputmask, @coitem output
if @rcode = 0
	begin
	update PMOZ set COItem=@coitem
	where UserId=@userid and ContractItem=@item
	end


goto PMOZ_loop



PMOZ_end:
	if @opencursor = 1
		begin
		close bcPMOZ
		deallocate bcPMOZ
		set @opencursor = 0
		end


bspexit:
	if @opencursor = 1
		begin
		close bcPMOZ
		deallocate bcPMOZ
		set @opencursor = 0
		end

	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemInitCreate] TO [public]
GO
