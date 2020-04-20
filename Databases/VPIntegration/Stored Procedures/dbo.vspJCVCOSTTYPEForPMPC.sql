SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE  proc [dbo].[vspJCVCOSTTYPEForPMPC]
/***********************************************************
 * Created By:	GF 08/10/2010 - issue #134354
 * Modified By: AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
 *
 *
 *
 *
 * USAGE:
 * this is just a modification of VCOSTTYPE to return needed parameters for PM Project Markups.
 * Returns defaults from JCCT to use.
 *
 *
 * INPUT PARAMETERS
 * co         Job Cost Company
 * job        Valid job
 * phase      phase to validate
 * costtype   cost type to validate(either CT or CT Abbrev)
 * override   optional if set to 'Y' will override 'lock phases' flag from JCJM
 *
 * OUTPUT PARAMETERS
 * costtypeout   Actual costtype validated
 * description   abbreviated cost type description
 * um            unit of measure from JCCH or JCPC.
 * trackhrs      Y if Tracking hours, otherwise N
 * MarkupPct	 markup percent
 * RoundAmount	 Round Amount Flag
 * msg           cost type abbreviation, or error message.
 *
 * It will validate by first checking in JCCT then JCCH
 *
 * This uses bspVJCCOSTTYPE to validate Cost Type
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = null, @job bJob = null, @phasegroup bGroup = null, @phase bPhase = null,
 @costtype varchar(10) = null, @override Char(1) = 'N', @costtypeout bJCCType = null output,
 @ctdesc varchar(255) = null output, @um bUM = null output, @trackhours bYN = 'N' output,
 @MarkupPct bPct = 0 output, @RoundAmount bYN = 'N' output,
 @msg varchar(255) = null output)
as
set nocount on
--#142350  - removing  @PhaseGroup
DECLARE @rcode int,
		@exists bYN,
		@pphase bPhase,
		@pgroup bGroup,
		@validcnt int,
		@billflag varchar(1),
		@itemunitflag varchar(1),
		@phaseunitflag varchar(1)

select @rcode = 0,  @msg = '', @validcnt = 0

if @phasegroup is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   	end
   
if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end

if @job in ('null', 'Null', 'NULL')
	begin
	select @job = null
	end

if @phase in ('null', 'Null', 'NULL')
	begin
	select @phase = null
	end


---- if no job or phase then validate cost type only
if isnull(@job,'') = '' or isnull(@phase,'') = ''
	begin
	exec @rcode = dbo.bspJCCostTypeVal @phasegroup, @costtype, @costtypeout output, @ctdesc output, @msg output
	if @rcode = 0 select @msg = @ctdesc
	---- get JCCT info
	select @trackhours=isnull(TrackHours,'N')
	from dbo.JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout
	goto bspexit
	end


---- validate job phase cost type
exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtype, @override, 
   			@pgroup output, @pphase output, @ctdesc output, @billflag output, @um output,
   			@itemunitflag output, @phaseunitflag output, @exists output, @costtypeout output, @msg output

if @rcode = 0 select @msg = @ctdesc

---- get JCCT info
select @trackhours=isnull(TrackHours,'N')
from dbo.JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtypeout

---- validate job status, cannot add to soft, hard closed jobs if JCCO flag does not allow
--if not exists(select top 1 1 from dbo.JCCH where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
--					and Phase=@phase and CostType=@costtypeout)
--	begin
--	exec @rcode = dbo.vspJCJMClosedStatusVal @jcco, @job, @msg output
--	end

if @rcode = 0 select @msg = @ctdesc


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCVCOSTTYPEForPMPC] TO [public]
GO
