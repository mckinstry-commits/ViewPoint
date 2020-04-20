SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSPhaseVal    Script Date: 8/28/99 9:33:33 AM ******/
     CREATE          proc [dbo].[bspPRTSPhaseVal]
     /*********************************************************************************
      * CREATED BY: EN 5/19/03
      * MODIFIED By : EN 12/01/04 - issue 26090 replace call to bspJCVPHASE with code designed to return warning if phase is in JCPM but not in JCJP
      *					mh 1/25/08 - 126856 - Added @crew input param.  Removed CostType output param.
	  *					mh 03/25/09 - 132377 - Change how Cost Type validates against JC.
	  *					mh 04/01/10 - 135231 - Modified how Cost Type validates against JC.  Bascially if the Labor
	  *							Cost Type does not exist on the Phase we do not want to be returning an error or validation.
	  *							
      * USAGE:
      * Validates and entered phase.  Like bspPRPhaseVal but needed to return default progress 
      * cost type and not insurance code.  Uses standard phase validation procedure.
      *
      * INPUT PARAMETERS
      *  @prco       PR Company
      *  @jcco       JC Company
      *  @job        Job
      *  @phasegrp   Phase Group used by JC Company
      *  @phase      Phase to validate
      *
      * OUTPUT PARAMETERS
      *  @phasedesc  Phase description
      *  @costtype	  Cost type from bJCCH
      *  @um		  Unit of Measure from bJCCH
      *  @msg        Error message, or description
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      **********************************************************************************/
	(@prco bCompany = null, @crew varchar(10), @jcco bCompany = null, @job bJob = null, @phasegrp bGroup = null,
	@phase bPhase = null, @costtype bJCCType = null, @phasedesc bDesc = null output, @costtypeout bJCCType = null output,
	@um bUM = null output, @msg varchar(255) = null output)

	as

	set nocount on

	declare @rcode int, @desc varchar(60), @pphase bPhase, @validphasechars int, @crewregec bEDLCode, 
	@jcmsg varchar(255), @phasenotonlockedjob bYN

	select @rcode = 0
   
	--26090 declarations and inits
	declare @PhaseGroup tinyint, @lockphases bYN, @active bYN

	select @phasenotonlockedjob = 'N'
   
	if @prco is null
	begin
		select @msg = 'Missing PR Company!', @rcode = 1
		goto bspexit
	end
     
	if @jcco is null
	begin
		select @msg = 'Missing JC Company!', @rcode = 1
		goto bspexit
	end
     
	if @job is null
	begin
		select @msg = 'Missing Job!', @rcode = 1
		goto bspexit
	end
     
	if @phase is null
	begin
		select @msg = 'Missing Phase!', @rcode = 1
		goto bspexit
	end
   
	if @phasegrp is null
	begin
		select @msg = 'Missing Phase Group!', @rcode = 1
		goto bspexit
	end
  
	-- validate JC Company -  get valid portion of phase code
	select @validphasechars = ValidPhaseChars
	from JCCO with (nolock) where JCCo = @jcco
	if @@rowcount <> 1
	begin
		select @msg = 'Invalid Job Cost Company!', @rcode = 1
		select @phasedesc=@msg
		goto bspexit
	end
   
	-- get Phase Group
	select @PhaseGroup = PhaseGroup
	from HQCO with (nolock) where HQCo = @jcco
	if @@rowcount <> 1
	begin
		select @msg = 'Phase Group for HQ Company ' + isnull(convert(varchar(3),@jcco),'') + ' not found!', @rcode = 1
		select @phasedesc=@msg
		goto bspexit
	end

   
	-- validate Phase Group
	if @PhaseGroup<>@phasegrp
	begin
		select @msg = 'Phase Group ' + isnull(convert(varchar(3), @PhaseGroup),'') + ' for HQ Company ' 
		+ isnull(convert(varchar(3),@jcco),'') + ' does not match Phase Group ' + isnull(convert(varchar(3), @phasegrp),''), @rcode = 1
		select @phasedesc=@msg
		goto bspexit
	end
   
	-- validate Job - get 'locked phases' flag
	select @lockphases = LockPhases
	from bJCJM where JCCo = @jcco and Job = @job
	if @@rowcount <> 1
	begin
		select @msg = 'Job ' + isnull(@job,'') + ' not found!', @rcode = 1
		select @phasedesc=@msg
		goto bspexit
	end

	-- first check Job Phases - exact match
	select @msg = Description, @pphase = Phase, @active = ActiveYN
	from bJCJP with (nolock)
	where JCCo = @jcco and Job = @job and Phase = @phase
	if @@rowcount = 1
	--JCJP exists
	begin
		if @active = 'Y' goto endofphaseval   -- Phase is on file and active
		select @msg = 'Phase ' + isnull(@phase,'') + ' is inactive!', @rcode = 1  -- Phase is on file, but inactive
		select @phasedesc=@msg
		goto bspexit
	end
   
    -- if lockphases and phase is not in JCJP, flag to warn and allow save if phase is found in JCPM
    if @lockphases = 'Y' select @phasenotonlockedjob = 'Y'
   
    -- check for a valid portion
    if isnull(@validphasechars,0) = 0 goto skipvalidportion
   
    -- format valid portion of Phase
    select @pphase = substring(@phase,1,@validphasechars) + '%'
   
    -- check valid portion of Phase in Job Phase table
    select Top 1 @msg = Description, @pphase = Phase
    from bJCJP with (nolock)
    where JCCo = @jcco and Job = @job and Phase like @pphase
    Group By JCCo, Job, Phase, Item, Description, ProjMinPct
 
    skipvalidportion:
    -- full match in Phase Master will override description from partial match in Job Phase
    select @msg = isnull(isnull(Description,@msg),''), @pphase = isnull(Phase,@phase)
    from bJCPM with (nolock)
    where PhaseGroup = @PhaseGroup and Phase = @phase

    -- if we've got a Description we've found a match */

	if @@rowcount<>0
	begin
		select @rcode = 0
		goto endofphaseval
	end

	-- check Phase Master using valid portion
	if @validphasechars > 0
	begin
		select @pphase = substring(@phase,1,@validphasechars) + '%'
		select Top 1 @msg = Description, @pphase = Phase
		from bJCPM with (nolock)
		where PhaseGroup = @PhaseGroup and Phase like @pphase
		Group By PhaseGroup, Phase, Description, ProjMinPct
		if @@rowcount = 1
		begin
			select @rcode = 0
			goto endofphaseval
		end
	end

    -- we are out of places to check
    select @msg = 'Phase ' + isnull(@phase,'') + ' not on file!', @rcode = 1
    select @phasedesc=@msg
    goto bspexit
   
     
	endofphaseval:  -- get default Cost Type from bPREC using reg ec set up in PR Company

--Issue 132377 - We still want to validate the cost type to attempt to pull in a UM.  However,
--if the cost type does not exist on the phase we will not raise an error.  Use 'P' as the 
--override flag. 'Y' does not do anything.

--If Cost Type is null do not bother to validate it.  This can happen if call is being made from PR Crews.  Crew Timehsheet
--Entry will not care about the Cost Type until Progress is entered at which time Cost Type will be required.

	if @costtype is not null
	begin
		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @PhaseGroup, @phase, @costtype, 'P', 
		null, null, null, null, @um output, null, null, null, null,	@jcmsg output

		if @rcode = 1
		begin
			select @msg = @jcmsg
			goto bspexit
		end

		select @costtypeout = CostType from JCCH where JCCo = @jcco and Job = @job and PhaseGroup = @PhaseGroup and
		Phase = @phase and CostType = @costtype
			
		if @costtypeout is null and @lockphases = 'N'
		begin
			select @costtypeout = CostType from JCPC where PhaseGroup = @PhaseGroup and
			Phase = @phase and CostType = @costtype
		end
	end
	
	if @costtypeout is null
	begin
		select @um = null
	end
	
	if @phasenotonlockedjob='Y' select @msg = 'Phase ' + isnull(@phase,'') + ' is not on job and job is locked!', @rcode = 1
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSPhaseVal] TO [public]
GO
