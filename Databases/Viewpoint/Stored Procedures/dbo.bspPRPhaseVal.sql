SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPhaseVal    Script Date: 8/28/99 9:33:33 AM ******/
   CREATE    proc [dbo].[bspPRPhaseVal]
   /*********************************************************************************
    * CREATED BY: kb 1/8/98
    * MODIFIED By : kb 10/23/98
    *             : DANF 04/26/2000  Add the return of insurance code for the Valid part of phase if the posted phase is not found.
   				SR 07/09/02 - issue 17738 pass @phasegrp to bspJCVPHASE
    *				EN 10/9/02 - issue 18877 change double quotes to single
	*			EN 2/18/09 #120115  inserted bJCJP validation before validating phase in bJCTI
	*			JVH 1/20/2011 #140544 Add validation to ensure that the phase group has been supplied
    *
    * USAGE:
    * Called from the PR Timecard Entry form to validates an entered phase, return
    * its description and default insurance code.  Uses standard phase validation procedure.
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
    *  @inscode    Insurance code - if default based on Phase
    *  @msg        Error message, or description
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    **********************************************************************************/
   	(@prco bCompany = null, @jcco bCompany = null, @job bJob = null, @phasegrp bGroup = null,
        @phase bPhase = null, @phasedesc bDesc = null output, @inscode bInsCode = null output,
        @msg varchar(255) = null output)
   as
   
   set nocount on
   
   declare @rcode int, @desc varchar(60), @pphase bPhase, @validphasechars int
   
   select @rcode = 0
   
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
   	   	
   if @phasegrp is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   	end
   
   if @phase is null
   	begin
   	select @msg = 'Missing Phase!', @rcode = 1
   	goto bspexit
   	end
   
   -- use standard Phase validation procedure to check Phase
   exec @rcode = bspJCVPHASE @jcco, @job, @phase, @phasegrp, 'N', @desc output, @msg output
   if @rcode = 1
   	begin
   	select @phasedesc=@msg
   	goto bspexit
   	end
   
   select @phasedesc = @msg    -- returned from validation procedure*/
   
   --select @phasegrp = PhaseGroup from HQCO where HQCo = @jcco
   --select @phasedesc = Description, @msg = Description
   --from JCJP
   --where JCCo = @jcco and Job = @job and PhaseGroup = @phasegrp and Phase = @phase
   
   -- get default Insurance Code if based on Phase
   if exists(select * from PRCO where PRCo = @prco and InsByPhase = 'Y')
       begin
	   select @inscode = InsCode from JCJP 
	   where JCCo = @jcco and Job = @job and PhaseGroup = @phasegrp and Phase = @phase
	
	   if @inscode is null
		  begin
		   select @inscode = t.InsCode
		   from JCTI t
		   join JCJM j on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
		   where t.JCCo = @jcco and PhaseGroup = @phasegrp and Phase = @phase
			   and j.Job = @job
	   
		   if @@rowcount = 0
			begin
			 -- check Phase Master using valid portion
			 -- validate JC Company -  get valid portion of phase code
			 select @validphasechars = ValidPhaseChars
			 from JCCO where JCCo = @jcco
			 if @@rowcount <> 0
			   begin
				if @validphasechars > 0
				 begin
				 select @pphase = substring(@phase,1,@validphasechars) + '%'
	   
				 select Top 1 @inscode = t.InsCode
				 from bJCTI t
				 join JCJM j on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
				 where t.JCCo = @jcco and t.PhaseGroup = @phasegrp and t.Phase like @pphase and j.Job = @job
				 Group By t.PhaseGroup, t.Phase, t.InsCode
				 end -- end valid part
			   end-- end select of jc company
			end -- end of full phase not found
		  end -- end of not found in JCJP
	   end -- end of ins by phase
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPhaseVal] TO [public]
GO
