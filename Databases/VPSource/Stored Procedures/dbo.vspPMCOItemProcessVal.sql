SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE    proc [dbo].[vspPMCOItemProcessVal]
/****************************************************************************
 * Created By:	GF 02/17/2006 for 6.x
 * Modified By:
 *
 *
 *
 *
 * USAGE:
 * Called from PMChgOrderItemInit form when process button is clicked.
 * Checks for items with valid CO Item and UM <> 'LS' and no units.
 * Checks for items with valid CO Item and UM = 'LS' and no amount (ACO only)
 *
 *
 * INPUT PARAMETERS:
 * PMCo			PM Company
 * UserId		User ID
 * Project		PM Project
 * PCO			PM Pending Change Order
 * ACO			PM Approved Change Order
 * 
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
(@pmco bCompany = null, @userid bVPUserName = null, @project bJob = null,
 @pco bPCO = null, @aco bACO = nujll, @msg varchar(2000) output)
as
set nocount on

declare @rcode int, @opencursor int, @item bContractItem, @coitem bPCOItem,
   		@um bUM, @addlunits bUnits, @amount bDollar, @intext varchar(1)


select @rcode = 0, @opencursor = 0, @msg = '', @intext = 'I'

-- -- -- if for an ACO then get internal/external flag
if isnull(@aco,'') <> ''
	begin
	select @intext=IntExt from PMOH where PMCo=@pmco and Project=@project and ACO=@aco
	end

-- -- -- declare cursor on PMOZ for UserId and COItem is not null
declare bcPMOZ cursor for select ContractItem, COItem, UM, AddlUnits, Amount
from PMOZ
where UserId = @userid and isnull(COItem,'') <> ''

-- -- -- open cursor
open bcPMOZ
set @opencursor = 1

PMOZ_loop:
fetch next from bcPMOZ into @item, @coitem, @um, @addlunits, @amount
if @@fetch_status <> 0 goto PMOZ_end

-- -- -- if co item is empty goto next
if isnull(@coitem,'') = '' goto PMOZ_loop

-- -- -- if @um <> 'LS' and @addlunits = 0 then create error message
if @um <> 'LS' and @addlunits = 0
	begin
	select @msg = isnull(@msg,'') + 'CO Item : ' + isnull(@coitem,'') + ' has a UM <> (LS) and no additional units.' + char(13) + char(10), @rcode = 1
	end

-- -- -- if @um = 'LS' and @amount = 0 and from ACO side then create error message
if @um = 'LS' and @amount = 0 and isnull(@aco,'') <> '' and @intext = 'E'
	begin
	select @msg = isnull(@msg,'') + 'CO Item : ' + isnull(@coitem,'') + ' has a UM = (LS) and no amount.' + char(13) + char(10), @rcode = 1
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

	if @rcode <> 0 select @msg = isnull(@msg,'') + ' Fix CO items or delete, then process again.'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCOItemProcessVal] TO [public]
GO
