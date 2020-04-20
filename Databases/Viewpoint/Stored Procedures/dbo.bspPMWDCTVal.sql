SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWDCTVal    Script Date: 8/28/99 9:35:21 AM ******/
CREATE proc [dbo].[bspPMWDCTVal]
/***********************************************************
 * CREATED:  GF 06/22/99
 * MODIFIED: DANF 03/16/00 Changed valid part of phase validation
 *           RM 02/28/01 - Changed Cost type to varchar(10)
 *			GF 12/11/2003 - #23212 - check error messages, wrap concatenated values with isnull
 *			GF 07/08/2004 - #24954 - if changing something else for phase cost type, allow change. Do not
 *							throw cost type exists error.
 *			GF 05/26/2006 - #27996 - 6.x changes
 *			GP 09/14/2009 - #135483 - fixed SP to actually return error message in @msg instead of just @desc.
 *
 *
 *
 * USAGE: Validates a Phase/CostType combination.
 *
 * It will validate by first checking in JCCT, then JCPC.
 * Then check valid portion of phase in JCPM, and
 * finally, check valid portion of phase in JCPC.
 *
 * INPUT PARAMETERS
 *  
 *    @jcco       JC Company
 *    @phasegroup Phase Group
 *    @phase      Phase
 *    @costtype   Cost type - may be passed as cost type number and or abbrevation
 *
 * OUTPUT PARAMETERS
 *    @desc             five character abbreviation
 *    @billflag         bill flag from JCPC
 *    @um               unit of measure from JCPC
 *    @itemunitflag     item unit flag from JCPC
 *    @phaseunitflag    phase unit flag from JCPC
 *    @costtypeout      numeric cost type
 *	  @trackhours		Track Hours flag from JCCT
 *    @msg              cost type abbreviation, or error message.
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = null, @phasegroup bGroup, @phase bPhase = null,
 @costtype varchar(10) = null, @importid varchar(10) = null, @sequence int = null,
 @desc varchar(255) = null output, @billflag char(1) = null output, @um bUM = null output, 
 @itemunitflag bYN = null output, @phaseunitflag bYN = null output, 
 @costtypeout bJCCType = null output, @trackhours bYN = null output,
 @msg varchar(255)= null output)
as
set nocount on

declare @rcode int, @validphasechars int, @inputmask varchar(30), @pphase bPhase

select @rcode = 0, @desc = ''

if @jcco is null
       begin
       select @msg = 'Missing JC Company!', @rcode = 1
       goto bspexit
       end

if @phase is null
       begin
       select @msg = 'Missing Phase!', @rcode = 1
       goto bspexit
       end

if @costtype is null
       begin
       select @msg = 'Missing Cost Type!', @rcode = 1
       goto bspexit
       end

------ if cost type is numeric then try to find
if isnumeric(@costtype) = 1
	begin
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Abbreviation, @trackhours=TrackHours
	from bJCCT with (nolock) where PhaseGroup = @phasegroup and CostType = convert(int,convert(float, @costtype))
	end

------ if not numeric or not found try to find as Sort Name
if @@rowcount = 0
	begin
	select @costtypeout = CostType, @desc = Abbreviation, @msg = Abbreviation, @trackhours=TrackHours
	from bJCCT with (nolock) where PhaseGroup = @phasegroup and Abbreviation like @costtype + '%'
	if @@rowcount = 0
		begin
		select @msg = 'Cost Type ' + isnull(@costtype,'') + ' not setup in Cost Type Master!', @rcode = 1
		goto bspexit
		end
	end

------ validate not already set up on phase
if @sequence is null or @sequence=0
	begin
	if exists (select 1 from bPMWD with (nolock) where PMCo=@jcco and ImportId=@importid
					and Phase=@phase and CostType=@costtypeout)
		begin
		select @msg = 'Cost Type already exists', @rcode=1
		goto bspexit
		end
	end
else
   	begin
   	------ #24954 check if cost type has changed first
   	if exists(select 1 from bPMWD where PMCo=@jcco and ImportId=@importid and Sequence=@sequence and CostType=@costtypeout)
			goto valid_part_phase

   	if exists (select 1 from bPMWD with (nolock) where PMCo=@jcco and ImportId=@importid and Phase=@phase
					and CostType=@costtypeout and Sequence <> @sequence)
		begin
   		select @msg = 'Cost Type already exists', @rcode=1
   		goto bspexit
   		end
	end



valid_part_phase:
------ get valid portion of phase
select @validphasechars = ValidPhaseChars
from bJCCO with (nolock) where JCCo = @jcco
if @@rowcount = 0
	begin
	select @msg = 'JC Co# ' + convert(varchar(3),@jcco) + ' not setup in JC Company Master!', @rcode = 1
	goto bspexit
	end

------ validate cost type in JC Cost Type master
select @desc = Abbreviation, @trackhours=TrackHours
from bJCCT with (nolock) where PhaseGroup = @phasegroup and CostType = @costtypeout
if @@rowcount = 0
	begin
	select @msg = 'Cost Type ' + convert(varchar(3),isnull(@costtypeout,'')) + ' not setup in JC Cost Type Master!', @rcode=1
	goto bspexit
	end

------ Check full phase in JCPC
select @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
from bJCPC with (nolock) where PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtypeout
if @@rowcount = 1
	begin
	select @rcode = 0
	goto bspexit
	end

------ Check valid portion
if @validphasechars > 0
	begin
	------ get the mask for bPhase
	select @inputmask = InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
	------ format valid portion of phase
	select @pphase = substring(@phase,1,@validphasechars) + '%'
	------ Check partial phase in JC Phase Cost Types
	select Top 1 @um=UM, @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
	from bJCPC with (nolock) where PhaseGroup = @phasegroup and Phase like @pphase and CostType = @costtypeout
	Group by PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag
	if @@rowcount = 1
		begin
		select @rcode = 0
		goto bspexit
		end
	end




bspexit:
	select @msg = isnull(@msg, @desc)
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWDCTVal] TO [public]
GO
