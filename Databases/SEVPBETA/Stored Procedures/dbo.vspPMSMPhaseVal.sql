SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[vspPMSMPhaseVal]
/***********************************************************
* CREATED By:	GF 01/02/2009 - issue #131576
* MODIFIED By:
*
*
* USAGE:
* validates JC Phase from Job Phases (JCJP) or Phase Master (JCPM)
* Used in PM Submittals.
* 1. Validate whole phase to JC Job Phases
* 2. Validate whole phase to JC Phase Master
* 3. Validate valid part of phase to JC Phase Master
*
* no phase passed, no phase found in JCJP/JCPM.
*
*
* INPUT PARAMETERS
*   JCCo        JCCO to get ValidPhaseChars From
*   PhaseGroup  JC Phase group for this company
*   Phase       Phase to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany, @project bJob, @phasegroup tinyint, @phase bPhase,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validphasechars int, @inputmask varchar(30), @pphase bPhase

select @rcode = 0, @msg='', @pphase = null

if @project is null
	begin
	select @msg = 'Missing project', @rcode = 1
	goto bspexit
	end

if @phase is null
	begin
	select @msg = 'Missing Phase', @rcode = 1
	goto bspexit
	end

---- first validate whole phase to JC Job Phase
select @msg = Description
from JCJP with (nolock)
where JCCo=@jcco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
if @@rowcount = 0
	begin
	---- validate whole phase to JC Phase Master
	select @msg = Description
	from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase = @phase
	if @@rowcount=0
		begin
		---- get valid phase characters for JC Company
		select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@jcco
		if @@rowcount = 0
			begin
			select @msg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
			goto bspexit
			end

		---- when no valid part phase characters then invalid phase
		if @validphasechars = 0
			begin
			select @msg = 'Missing Phase', @rcode = 1
			goto bspexit
			end

		---- get the mask for bPhase
		select @inputmask=InputMask from DDDTShared with (nolock) where Datatype = 'bPhase'
		---- format valid portion of phase
		select @pphase=substring(@phase,1,@validphasechars) + '%'

		---- validate valid part phase to JC Phase Master
		select TOP 1 @msg = Description
		from JCPM with (nolock) where PhaseGroup = @phasegroup and Phase like @pphase
		Group By PhaseGroup, Phase, Description
		if @@rowcount = 0
			begin
			select @msg = 'Phase not setup in Phase Master.', @rcode = 1
			goto bspexit
			end
       end
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSMPhaseVal] TO [public]
GO
