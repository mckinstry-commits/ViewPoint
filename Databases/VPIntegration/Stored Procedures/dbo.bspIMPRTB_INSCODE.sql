SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMPRTB_INSCODE    Script Date: 8/28/99 9:34:28 AM ******/
   CREATE    proc [dbo].[bspIMPRTB_INSCODE]
   /********************************************************
   * CREATED BY: 	DANF 05/16/00
   * MODIFIED BY: DANF 12/2/02 - removed select * from PRCO
   *				EN 12/14/2009 #136347 use JCJP ins code over JCIN ins code
   *
   * USAGE:
   * 	Retrieves insurance codee based on setup parameters
   *
   * INPUT PARAMETERS:
   *	PR Company
   *   PR Employee
   *   JC Job Cost Company
   *   JC Job
   *   Rate
   *   PR Insurance Code
   *
   * OUTPUT PARAMETERS:
   *	unemployment STATE FROM PREH OR PRCO OR JCJM
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   (@prco bCompany = 0, @employee bEmployee, @jcco bCompany, @job bJob, @phase bPhase, @phasegrp bGroup, @inscode bInsCode output,
    @insstate bState, @Rate bUnitCost, @msg varchar(60) output) as
   set nocount on
   declare @rcode int, @officestate bState, @empuseins bYN, @empinscode bInsCode, @inscodeopt bYN,
           @jobstate bState, @overinscode bInsCode, @validphasechars tinyint, @pphase bPhase
   select @rcode = 0, @overinscode = null, @inscode = null
   
   select @officestate = OfficeState, @inscodeopt = InsStateOpt
   from PRCO
   where PRCo = @prco
   if @@rowcount = 0
   	begin
   	select @msg = 'Missing PR Company#!', @rcode = 1
   	goto bspexit
   	end
   
   select @empinscode = InsCode, @empuseins = UseIns
   from bPREH
   where PRCo = @prco and Employee = @employee
   
   if @@rowcount = 0
      begin
      select @msg = 'Employee is not on File.', @rcode=1, @employee=0, @inscode = null
      goto bspexit
      end
   If @empuseins = 'Y' 
	  begin
	  select @inscode = @empinscode
	  goto bspexit
	  end
   
   -- get default Insurance Code if based on Phase
   if exists (select * from PRCO where PRCo = @prco and InsByPhase = 'Y')
       begin -- look for ins code in JCJP/JCTI if PRCO set to default ins code based on phase
	   --#136347
	   select @inscode = InsCode from JCJP 
	   where JCCo = @jcco and Job = @job and PhaseGroup = @phasegrp and Phase = @phase
	
	   if @inscode is null
		begin -- ins code not found in JCJP
		   select @inscode = t.InsCode
		   from JCTI t
		   join JCJM j on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
		   where t.JCCo = @jcco and PhaseGroup = @phasegrp and Phase = @phase
			   and j.Job = @job
	   
		   if @@rowcount = 0
			 begin -- ins code not found in JCTI using full phase
			 -- check Phase Master using valid portion
			 -- validate JC Company -  get valid portion of phase code
			 select @validphasechars = ValidPhaseChars
			 from JCCO where JCCo = @jcco
			 if @@rowcount <> 0
			   begin
				if @validphasechars > 0
				 begin -- check JCTI using valid part of phase
				 select @pphase = substring(@phase,1,@validphasechars) + '%'
	   
				 select Top 1 @inscode = t.InsCode
				 from bJCTI t
				 join JCJM j on j.JCCo = t.JCCo and j.InsTemplate = t.InsTemplate
				 where t.JCCo = @jcco and t.PhaseGroup = @phasegrp and t.Phase like @pphase and j.Job = @job
				 Group By t.PhaseGroup, t.Phase, t.InsCode
				 end -- end valid part
			   end-- end select of jc company
			end -- end of full phase not found
		  end -- end of ins by phase

		end -- end of ins by job/phase
   
	--#136347 if ins code was not found elsewhere default to empl inscode
	if isnull(@inscode,'') = '' select @inscode = @empinscode
   
   select @overinscode = OverrideInsCode
   from PRIN
   where PRCo = @prco and State = @insstate and InsCode = @inscode
         and UseThreshold = 'Y' and ThresholdRate <= @Rate
   if @overinscode is not null select @inscode = @overinscode
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Insurance code') + char(13) + char(10) + '[bspIMPRTB_INSCODE]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_INSCODE] TO [public]
GO
