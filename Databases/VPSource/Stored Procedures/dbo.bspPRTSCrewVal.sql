SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSCrewVal    Script Date: 8/28/99 9:33:16 AM ******/
    CREATE      proc [dbo].[bspPRTSCrewVal]
    /***********************************************************
     * CREATED BY: EN 2/26/03
     * MODIFIED By : EN EN 12/08/03 - issue 23061  added isnull check, with (nolock), and dbo
	 *				 mh 4/26/07 - recode issue 28073.  If Shift is null return 1 for @shift.
	 *				 mh 1/25/08 - Issue 126856
	 *				 mh 04/01/09 - Issue 132377
     *
     * USAGE:
     * validates PR Crew from PRCR for crew timesheet
     * an error is returned if any of the following occurs
     *
     * INPUT PARAMETERS
     *   PRCo   PR Co to validate against 
     *   Crew   PR Crew to validate
     * OUTPUT PARAMETERS
     *	 @jcco	JC Co stored in bPRCR
     *	 @job	Default Job
     *	 @shift	Default Shift
     *	 @phasegroup	Default Phase Group
     *	 @phase1	Default Phase1
     *	 @phase2	Default Phase2
     *	 @phase3	Default Phase3
     *	 @phase4	Default Phase4
     *	 @phase5	Default Phase5
     *	 @phase6	Default Phase6
     *	 @phase7	Default Phase7
     *	 @phase8	Default Phase8
     *	 @prgroup  Default PR Group
     *	 @approvalreq	Approval Required flag
     *   @msg      error message if error occurs otherwise Description of Crew
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/ 
    
    (@prco bCompany = 0, @crew varchar(10) = null, @jcco bCompany output, @job bJob output,
     @shift tinyint output, @phasegroup bGroup output, @phase1 bPhase output, @phase2 bPhase output,
     @phase3 bPhase output, @phase4 bPhase output, @phase5 bPhase output, @phase6 bPhase output,
     @phase7 bPhase output, @phase8 bPhase output, @prgroup bGroup output, @approvalreq bYN output,
     @costtype bJCCType output, @msg varchar(255) output)

    as
    
    set nocount on
    
    declare @rcode int, @status tinyint, @lockphases bYN, @crafttemplate smallint, 
	@regecovride bEDLCode, @errmsg varchar(255), @um bUM
    
    select @rcode = 0, @regecovride = null
    
    if @prco is null
    	begin
    	select @msg = 'Missing PR Company!', @rcode = 1
    	goto bspexit
    	end
    
    if @crew is null
    	begin
    	select @msg = 'Missing PR Crew!', @rcode = 1
    	goto bspexit
    	end

	--28073 - if Shift is null set @shift to 1.    
	select @jcco=JCCo, @job=Job, @shift=isnull(Shift,1), @phasegroup=PhaseGroup, @phase1=Phase1, @phase2=Phase2,
	@phase3=Phase3, @phase4=Phase4, @phase5=Phase5, @phase6=Phase6, @phase7=Phase7, @phase8=Phase8,
	@prgroup=PRGroup, @approvalreq=ApprovalReq, @regecovride = RegECOvride, @msg = Description
	from dbo.PRCR with (nolock)
	where PRCo = @prco and Crew=@crew 
	
	if @@rowcount = 0
	begin
		select @msg = 'PR Crew not on file!', @rcode = 1
		goto bspexit
	end

	--Issue 126856 - need to make sure we have a phase group
	if @phasegroup is null
	begin
		select @msg = 'Phase group has not been set up in HQ.', @rcode = 1
		goto bspexit
	end

	
	--Issue 126856
	--Check Reg Earning Code.  If not null then get the JCCostType from PREC.  If null 
	--then we need to fall back to PRCO
	if @regecovride is null
	begin
		select @regecovride = CrewRegEC from dbo.PRCO (nolock) where PRCo = @prco
		if @regecovride is null
		begin
			select @msg = 'Unable obtain Crew Timesheet Earnings Code and JC Cost Type.  Review PR Crew and PR Company setups.', @rcode = 1
			goto bspexit
		end
	end

	If @regecovride is not null
	begin
		select @costtype = JCCostType 
		from dbo.PREC (nolock) where PRCo = @prco and EarnCode = @regecovride


		if @costtype is null
		begin
		select @msg = 'Unable to obtain JC Cost Type.  Review Earnings Code setup.', @rcode = 1
		goto bspexit
		end
	end


    --valid jcco and job must exist in crew setup to post timesheets
    exec @rcode = bspPRTSJobVal @jcco, @job, @status output, @lockphases output, @crafttemplate output, @errmsg  output
    if @rcode<>0
    	begin
    	select @msg = isnull(@errmsg,'') + '  Resolve in crew setup.'
    	goto bspexit
    	end

--Issue 132377 -- do check for valid cost types against JC until the user enters Progress units.  
--at this point we will just default whatever is set up in PREC or overriden in PR Crew setup.
    
--	--We now have a cost type to default and a valid jcco/job.  Verify the Phase/default Cost Type 
--	--combinations are valid by executing bspJCVCOSTTYPE for each phase returned from PRCR
--
--	if @phase1 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase1, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase2 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase2, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase3 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase3, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase4 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase4, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase5 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase5, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase6 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase6, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase7 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase7, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end
--
--	if @phase8 is not null
--	begin
--		exec @rcode = bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase8, @costtype, 'N', 
--		null, null, null, null, @um output, null, null, null, null, @errmsg output
--
--		if @rcode = 1 
--		begin
--			select @msg = @errmsg
--			goto bspexit
--		end
--	end

--end 132377

    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSCrewVal] TO [public]
GO
