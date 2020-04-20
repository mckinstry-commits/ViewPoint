SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMVPHASE    Script Date: 8/28/99 9:33:08 AM ******/
   CREATE procedure [dbo].[bspPMVPHASE]
   /***********************************************************
    * CREATED BY:	MH 07/20/99
    * Modified By:	GF 12/11/2003 - #23212 - check error messages, wrap concatenated values with isnull
    *
    * USAGE:
    * Phase validation procedure for PMDailyLog. 
    * 1st - Checks for exact match in Job Phase table
    *      If found, must be active, else rejected.  If locked phases is on, Phase must exist here.
    * 2rd - Checks Phase Master for exact match - if exists, use description, etc.
    *
    *
    * INPUT PARAMETERS
    *    @jcco         Job Cost Company
    *    @job          Valid job
    *    @phase        Phase to validate
    *    @override     Optional - if set to 'Y' will override 'lock phases' flag in bJCJM
    *
    * OUTPUT PARAMETERS
    *    @desc         phase description
    *    @PhaseGroup   phase group from bHQCO
    *    @msg          Phase description, or error message.
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
    (@jcco bCompany, @job bJob, @phase bPhase, @override bYN = 'N', @msg varchar(255) = null output)
   
   as
   set nocount on
   
   declare @rcode int, @desc varchar(255), @PhaseGroup tinyint, @lockphases bYN, @active bYN
   
   
   select @rcode = 0
   
   if @jcco is null
   	begin
   	select @desc = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @job is null
   	begin
   	select @desc = 'Missing Job!', @rcode = 1
   	goto bspexit
   	end
   if @phase is null
   	begin
   	select @desc = 'Missing Phase!', @rcode = 1
   	goto bspexit
   	end
   
   -- get Phase Group
   select @PhaseGroup = PhaseGroup
   from HQCO with (nolock) where HQCo = @jcco
   if @@rowcount <> 1
       begin
       select @desc = 'Phase Group for HQ Company ' + convert(varchar(3),@jcco) + ' not found!', @rcode = 1
       goto bspexit
       end
   
   -- validate Job - get 'locked phases' flag
   select @lockphases = LockPhases
   from JCJM with (nolock) 
   where JCCo = @jcco and Job = @job
   if @@rowcount <> 1
       begin
       select @desc = 'Job: ' + isnull(@job,'') + ' not found!', @rcode = 1
       goto bspexit
       end
   
   -- first check Job Phases - exact match
   select @desc = Description, @active = ActiveYN
   from JCJP with (nolock) 
   where JCCo = @jcco and Job = @job and Phase = @phase
   if @@rowcount = 1
       begin
       if @active = 'Y' goto bspexit
       select @desc = 'Phase: ' + isnull(@phase,'') + ' is inactive!', @rcode = 1  -- Phase is on file, but inactive
       goto bspexit
   
       end
   
   -- check 'locked phases' and override
   if @lockphases = 'Y' and @override <> 'Y'
       begin
       select @desc = 'Locked Phase: ' + isnull(@phase,'') + ' is not on job!', @rcode = 1   -- No new Phases allowed
       goto bspexit
       end
   
   -- if not in Job Phases and 'locked phases' is off look in Phase Master
   select @desc = Description
   from JCPM with (nolock) 
   where Phase = @phase and PhaseGroup = @PhaseGroup
   
   if @@rowcount = 1
       begin
       goto bspexit
       end
   else
   	-- we are out of places to check
       begin
       select @desc = 'Phase: ' + isnull(@phase,'') + ' not on file!', @rcode = 1
       goto bspexit
       end
   
   
   
   
   bspexit:
       select @msg = @desc    
   	if @rcode <> 0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMVPHASE] TO [public]
GO
