SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSInitUsage    Script Date: 8/28/99 9:35:39 AM ******/
     CREATE           proc [dbo].[bspPRTSInitUsage]
     /****************************************************************************
      * CREATED BY: EN 2/28/03
      * MODIFIED By : EN 4/1/04 issue 23940 when calc usage totals, use isnull
      *				  EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
	  *				  MH 07/02/08 - issue 128703.  Need to wrap hours fields from PRRE in isnull 
	  *					functions and translate null to 0
	  *               ECV 10/28/10 - Issue 131985 calculate usage correctly for multiple employees
      *
      * USAGE:
      * Initialized equipment usage in bPRRQ based on the employee hours posted in bPRRE.
      * 
      *  INPUT PARAMETERS
      *   @prco			PR Company
      *   @crew			PR Crew
      *   @postdate		Posting Date
      *	 @sheet			Timesheet Sheet #
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ****************************************************************************/ 
     (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
      @sheet smallint = null, @msg varchar(60) output)
     as
     
     set nocount on
     
     declare @rcode int, @numrows int
     
     declare @employee bEmployee, @emco bCompany, @emgroup bGroup, @equipment bEquip,
     @phase1usage bHrs, @phase2usage bHrs, @phase3usage bHrs, @phase4usage bHrs,
     @phase5usage bHrs, @phase6usage bHrs, @phase7usage bHrs, @phase8usage bHrs, @usagepct bPct,
     @phase1rev bRevCode, @phase2rev bRevCode, @phase3rev bRevCode, @phase4rev bRevCode, 
     @phase5rev bRevCode, @phase6rev bRevCode, @phase7rev bRevCode, @phase8rev bRevCode, @totalusage bHrs
     
     select @rcode = 0
     
     -- validate PRCo
     if @prco is null
     	begin
     	select @msg = 'Missing PR Co#!', @rcode = 1
     	goto bspexit
     	end
     -- validate Crew
     if @crew is null
     	begin
     	select @msg = 'Missing Crew!', @rcode = 1
     	goto bspexit
     	end
     -- validate PostDate
     if @postdate is null
     	begin
     	select @msg = 'Missing Timecard Date!', @rcode = 1
     	goto bspexit
     	end
     -- validate Sheet number
     if @sheet is null
     	begin
     	select @msg = 'Missing Sheet #!', @rcode = 1
     	goto bspexit
     	end
     
     -- initialize phase usage variables
     select @phase1usage=0, @phase2usage=0, @phase3usage=0, @phase4usage=0, 
    	@phase5usage=0, @phase6usage=0, @phase7usage=0, @phase8usage=0
    
     -- spin through equipment in timesheet
     select @emco = min(EMCo) from PRRQ 
     where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet
     WHILE @emco is not null
     	BEGIN
     	select @emgroup = min(EMGroup) from PRRQ 
     	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco
     	WHILE @emgroup is not null
     		BEGIN
     		select @equipment = min(Equipment) from PRRQ
     		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     			EMCo=@emco and EMGroup=@emgroup
     		WHILE @equipment is not null
     			BEGIN
     			-- Issue 131985 ECV Add loop by Employee within Equpment 
				select @employee=min(Employee)
   				from PRRQ where PRCo=@prco and Crew=@crew and PostDate=@postdate and 
     			SheetNum=@sheet and EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
     			WHILE @employee is not null
     				BEGIN
     				select @phase1rev=Phase1Rev, @phase2rev=Phase2Rev,
   						@phase3rev=Phase3Rev, @phase4rev=Phase4Rev, @phase5rev=Phase5Rev, 
   						@phase6rev=Phase6Rev, @phase7rev=Phase7Rev, @phase8rev=Phase8Rev
   					from PRRQ where PRCo=@prco and Crew=@crew and PostDate=@postdate and 
     					SheetNum=@sheet and EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
     					and Employee=@employee -- added ECV #131985
     				-- if equip-only, skip to next
     				if @employee is null goto NextPRRQ
	   
   					--check for optional usage percentage in crew setup ... default to 100% if none found
					--select @usagepct=1 -- removed ECV #131985 Change default to  0%
					select @usagepct=0	 -- added ECV #131985
   					select @usagepct=UsagePct from PRCW
   					where PRCo=@prco and Crew=@crew and Employee=@employee and Equipment=@equipment

					-- Issue 131985 ECV Reset hours of usage variables to zero.
     				select @phase1usage=0, @phase2usage=0, @phase3usage=0, @phase4usage=0, @phase5usage=0, @phase6usage=0, 
     						@phase7usage=0, @phase8usage=0

					--issue 128703        
     				-- get usage hours from bPRRE LineSeq 1 entries, based on regular hrs + overtime hrs + doubletime hrs
   					-- apply percentage from crew setup
     				select @phase1usage=(isnull(Phase1RegHrs,0)+isnull(Phase1OTHrs,0)+isnull(Phase1DblHrs,0))*@usagepct,
     					@phase2usage=(isnull(Phase2RegHrs,0)+isnull(Phase2OTHrs,0)+isnull(Phase2DblHrs,0))*@usagepct,
     					@phase3usage=(isnull(Phase3RegHrs,0)+isnull(Phase3OTHrs,0)+isnull(Phase3DblHrs,0))*@usagepct,
     					@phase4usage=(isnull(Phase4RegHrs,0)+isnull(Phase4OTHrs,0)+isnull(Phase4DblHrs,0))*@usagepct,
     					@phase5usage=(isnull(Phase5RegHrs,0)+isnull(Phase5OTHrs,0)+isnull(Phase5DblHrs,0))*@usagepct,
     					@phase6usage=(isnull(Phase6RegHrs,0)+isnull(Phase6OTHrs,0)+isnull(Phase6DblHrs,0))*@usagepct,
     					@phase7usage=(isnull(Phase7RegHrs,0)+isnull(Phase7OTHrs,0)+isnull(Phase7DblHrs,0))*@usagepct,
     					@phase8usage=(isnull(Phase8RegHrs,0)+isnull(Phase8OTHrs,0)+isnull(Phase8DblHrs,0))*@usagepct
     				from bPRRE where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     					Employee=@employee and LineSeq=1 
	     
   					-- only include usage hours from bPRRE when rev code basis is Hourly
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase1rev) <> 1
   						select @phase1usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase2rev) <> 1
   						select @phase2usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase3rev) <> 1
   						select @phase3usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase4rev) <> 1
   						select @phase4usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase5rev) <> 1
   						select @phase5usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase6rev) <> 1
   						select @phase6usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase7rev) <> 1
   						select @phase7usage=0
   					if (select HrsPerTimeUM from bEMRC where EMGroup=@emgroup and RevCode=@phase8rev) <> 1
   						select @phase8usage=0
		   
   					-- compute total usage
   					select @totalusage=isnull(@phase1usage,0)+isnull(@phase2usage,0)+isnull(@phase3usage,0)+
   						isnull(@phase4usage,0)+isnull(@phase5usage,0)+isnull(@phase6usage,0)+isnull(@phase7usage,0)+
   						isnull(@phase8usage,0)
		   
   					if @totalusage=0 select @totalusage=null
		   
   					-- update bPRRQ
     					update bPRRQ
     					set Phase1Usage=@phase1usage, Phase2Usage=@phase2usage, Phase3Usage=@phase3usage,
     						Phase4Usage=@phase4usage, Phase5Usage=@phase5usage, Phase6Usage=@phase6usage,
     						Phase7Usage=@phase7usage, Phase8Usage=@phase8usage, TotalUsage=@totalusage
     					where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     						EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
		     				and Employee=@employee -- added ECV #131985
					-- Issue 131985 ECV Add loop by Employee within Equpment 
					select @employee=min(Employee)
   					from PRRQ where PRCo=@prco and Crew=@crew and PostDate=@postdate and 
     					SheetNum=@sheet and EMCo=@emco and EMGroup=@emgroup and Equipment=@equipment
     					and Employee > @employee
					END
				--     
     NextPRRQ:	-- get next bPRRQ entry
     			select @equipment = min(Equipment) from PRRQ
     			where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and
     				EMCo=@emco and EMGroup=@emgroup and Equipment>@equipment
     			END
     		select @emgroup = min(EMGroup) from PRRQ 
     		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and
     			EMGroup>@emgroup
     		END
     	select @emco = min(EMCo) from PRRQ 
     	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo>@emco
     	END
     
     
     bspexit:
     	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTSInitUsage]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSInitUsage] TO [public]
GO
