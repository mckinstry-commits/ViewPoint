SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE proc [dbo].[bspPMInterfaceItemAttachGet]
/***********************************************************
* Created By:	GF 02/14/2008 issue #126936
* Modified By:
*
*
* USAGE:
* Called from PM Interface when interfacing change order after interface is complete. This procedure
* will return a string of PMOI.ACOItems with the PMOI.UniqueAttchId. Used in the front-end to copy
* PMOI attachments to JCOI.
*
*
* INPUT PARAMETERS
*  PMCo			PM Company 
*  Project		PM Project
*  ACO			PM ACO
*
* OUTPUT PARAMETERS
* @itemstring	returns string of ACO Items and UniqueAttchIds that will be copied to JCOI
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @aco bACO = null,
 @itemstring varchar(max) = null output)
as
set nocount on

declare @rcode int, @opencursor int, @acoitem bACOItem, @uniqueattchid uniqueidentifier,
		@attachid varchar(max)

select @rcode = 0, @opencursor = 0

if @pmco is null or @project is null or @aco is null goto bspexit



---- declare cursor on PMOI for the ACO items
declare bcPMOI cursor LOCAL FAST_FORWARD for select ACOItem
from PMOI a
where PMCo=@pmco and Project=@project and ACO=@aco and isnull(ACOItem,'') <> ''

---- open cursor
open bcPMOI
set @opencursor = 1

---- loop through PMOI Items
PMOI_loop:
fetch next from bcPMOI into @acoitem

if (@@fetch_status <> 0) goto PMOI_end

---- if ACO Item does not exist in JCOI skip to next
if not exists(select JCCo from JCOI with (nolock) where JCCo=@pmco and Job=@project
				and ACO=@aco and ACOItem=@acoitem)
	begin
	goto PMOI_loop
	end

---- if JCOI.UniqueAttchID is not null, skip
if exists(select JCCo from JCOI with (nolock) where JCCo=@pmco and Job=@project
				and ACO=@aco and ACOItem=@acoitem and UniqueAttchID is not null)
	begin
	goto PMOI_loop
	end

---- get PMOI.UniqueAttchID
select @attachid = UniqueAttchID
from PMOI with (nolock) where PMCo=@pmco and Project=@project and ACO=@aco and ACOItem=@acoitem
if @@rowcount = 0 goto PMOI_loop


---- add the item and unique attachment id to the @itemstring so that the front-end can parse and copy
if isnull(@itemstring,'') = ''
	begin
	select @itemstring = @acoitem + ':' + @attachid + ','
	end
else
	begin
	select @itemstring = @itemstring + @acoitem + ':' + @attachid + ','
	end

goto PMOI_loop


PMOI_end:
---- close and deallocate cursor
if @opencursor = 1
	begin
	close bcPMOI
	deallocate bcPMOI
	set @opencursor = 0
	end



bspexit:
	---- close and deallocate cursor
	if @opencursor = 1
		begin
		close bcPMOI
		deallocate bcPMOI
		set @opencursor = 0
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMInterfaceItemAttachGet] TO [public]
GO
