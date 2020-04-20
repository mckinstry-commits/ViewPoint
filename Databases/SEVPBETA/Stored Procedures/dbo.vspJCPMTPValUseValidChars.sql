SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE  proc [dbo].[vspJCPMTPValUseValidChars]
/***********************************************************
 * Created By:	GF 04/26/2005
 * Modified By:
 *
 *
 * USAGE:
 * validates JC Phase from Phase Master.
 * First uses Whole phase, then valid part of phase.
 * Returns the description from PMTP if exists to display as key description.
 *  
 * no phase passed, no phase found in JCPM.
 *
 *
 * INPUT PARAMETERS
 *   JCCo        JCCO to get ValidPhaseChars From
 *   PhaseGroup  JC Phase group for this company
 *   Phase       Phase to validate
 *
 * OUTPUT PARAMETERS
 *   @Desc     Description of phase
 *   @msg      error message if error occurs otherwise Description of Template description
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany, @template varchar(10), @phasegroup bGroup, @phase bPhase,
 @jcpm_desc bDesc output, @pphase varchar(20)=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validphasechars int, @inputmask varchar(30)

select @rcode = 0, @msg='', @jcpm_desc = ''

if @phase is null
  	begin
  	select @msg = 'Missing Phase', @rcode = 1
  	goto bspexit
  	end

-- validate phase
select @msg = Description, @jcpm_desc = Description, @pphase=Phase
from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase = @phase
if @@rowcount=0
	begin
	select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@jcco
	if @@rowcount=0
		begin
		select @msg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
		goto bspexit
		end

	if @validphasechars=0
		begin
		select @msg = 'Missing Phase', @rcode = 1
		goto bspexit
		end

	-- get the mask for bPhase
	select @inputmask=InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
  
	-- format valid portion of phase
	select @pphase=substring(@phase,1,@validphasechars) + '%'
	select TOP 1 @msg = Description, @jcpm_desc = Description
	from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase like @pphase
	Group By PhaseGroup, Phase, Description
	if @@rowcount = 0
		begin
		select @msg = 'Phase not setup in Phase Master.', @rcode = 1
		goto bspexit
		end
	end

-- -- -- look for PMTP description for phase
select @msg = isnull(Description,@msg)
from PMTP where PMCo=@jcco and Template=@template and PhaseGroup=@phasegroup and Phase=@phase






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPMTPValUseValidChars] TO [public]
GO
