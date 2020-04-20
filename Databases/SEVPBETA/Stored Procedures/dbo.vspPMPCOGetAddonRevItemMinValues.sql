SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPCOGetAddonRevItemMinValues  Script Date: 8/28/99 9:33:05 AM ******/
CREATE proc [dbo].[vspPMPCOGetAddonRevItemMinValues]
/***********************************************************
 * CREATED BY:	GF 02/17/2009 - ISSUE #132308
 * MODIFIED BY:
 *
 *
 *
 *
 * USAGE: Called from bspPMPCOApprove to set the lowest revenue item when addons approved.
 * Needed so that we know which ACO Items to not include when getting next sequential item #.
 *
 *
 * INPUT PARAMETERS
 * PMCO
 * PROJECT
 * PCOType
 * PCO
 * PCOItem
 *
 *
 * OUTPUT PARAMETERS
 *
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null,
 @minseqitem int = 0 output, @fixeditems varchar(max) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @opencursor tinyint, @revitem bContractItem,
		@revuseitem char(1), @revstartatitem int, @inputmask varchar(30),
		@inputlength varchar(10), @tmpitem varchar(10), @revfixedacoitem bACOItem,
		@revacoitem varchar(10), @minfixeditem varchar(10)


select @rcode = 0, @opencursor = 0, @minseqitem = 0, @fixeditems = ';', @minfixeditem = '9999999999'

------ get the mask for bPCOItem
select @inputmask=InputMask, @inputlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bACOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@inputlength,'') = '' select @inputlength = '10'
if @inputmask in ('R','L')
   	begin
   	select @inputmask = @inputlength + @inputmask + 'N'
   	end

---- declare cursor on PMPA Project Addons for redirect addons
declare bcPMPA cursor local FAST_FORWARD
	for select RevItem, RevUseItem, RevStartAtItem, RevFixedACOItem
from bPMPA with (nolock) where PMCo=@pmco and Project=@project and RevRedirect = 'Y'

-- open cursor
open bcPMPA
-- set open cursor flag to true
select @opencursor = 1

PMPA_loop:
fetch next from bcPMPA into @revitem, @revuseitem, @revstartatitem, @revfixedacoitem

if @@fetch_status <> 0 goto PMPA_end

set @tmpitem = null
set @revacoitem = null

---- must have revenue item if redirecting addon fee
if isnull(@revitem,'') = ''
	begin
	goto PMPA_loop
	end

---- if using revenue item
if @revuseitem = 'U'
	begin
	---- verify data length of revenue item will fit in aco item
	if datalength(ltrim(rtrim(@revitem))) > 10
		begin
		goto PMPA_loop
		end

	---- format aco item from revenue item
	select @tmpitem = ltrim(rtrim(@revitem))
    exec dbo.bspHQFormatMultiPart @tmpitem, @inputmask, @revacoitem output
	if isnull(@revacoitem,'') = ''
		begin
		goto PMPA_loop
		end

	---- add to fixed revenue items character string
	select @fixeditems = isnull(@fixeditems,'') + @revacoitem + ';'
	if @revacoitem < isnull(@minfixeditem,'9999999999') set @minfixeditem = @revacoitem
	goto PMPA_loop
	end


---- if using fixed ACO item
if @revuseitem = 'F'
	begin
	if isnull(@revfixedacoitem,'') = ''
		begin
		goto PMPA_loop
		end

	---- add to fixed revenue items character string
	select @fixeditems = isnull(@fixeditems,'') + @revfixedacoitem + ';'
	if @revfixedacoitem < isnull(@minfixeditem,'9999999999') set @minfixeditem = @revfixedacoitem
	goto PMPA_loop
	end



---- need to create a new ACO Item using the starting ACO Item from PMPA
if @revuseitem = 'S'
	begin
	if isnull(@revstartatitem,0) < 1
		begin
		goto PMPA_loop
		end

	if @minseqitem = 0
		begin
		select @minseqitem = @revstartatitem
		goto PMPA_loop
		end

	---- check if start at item < current minimum item
	if @revstartatitem < @minseqitem
		begin
		set @minseqitem = @revstartatitem
		goto PMPA_loop
		end
	end

goto PMPA_loop



PMPA_end:
if @opencursor = 1
	begin
	close bcPMPA
	deallocate bcPMPA
	select @opencursor = 0
	end


---- if we have fixed items and no minimum sequential item then set @minseqitem to min(FixedItem)
----if @minseqitem = 0 and datalength(@fixeditems) > 1 set @minseqitem = convert(int,@minfixeditem)



bspexit:
	if @opencursor = 1
		begin
		close bcPMOA
		deallocate bcPMOA
		select @opencursor = 0
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOGetAddonRevItemMinValues] TO [public]
GO
