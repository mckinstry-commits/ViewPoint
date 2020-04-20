SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSCostTypesVal    Script Date: 8/28/99 9:35:39 AM ******/
   CREATE              proc [dbo].[bspPRTSCostTypesVal]
   /****************************************************************************
    * CREATED BY: EN 6/6/03
    * MODIFIED By : EN 12/08/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				EN 2/13/04 - issue 23788  return error if equip cost type is null
    *				EN 2/13/04 - issue 23794  validate rev code
    *				EN 4/27/04 - issue 24173 check for inactive equipment
    *				EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
    *				mh 9/5/07 - issue ????? - bspPREMUsageCostTypeVal was changed to add @costtypeout output
	*							param.
    *
    * USAGE:
    * Validate equipment cost types on a timesheet.
    * 
    *  INPUT PARAMETERS
    *   	@prco			PR Company
    *   	@crew			PR Crew
    *   	@postdate		Posting Date
    *		@sheet			Timesheet Sheet #
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************/ 
   (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
    @sheet smallint = null, @msg varchar(255) output)
   
   as
    
   set nocount on
     
   declare @rcode int, @phasenum tinyint, @jcco bCompany, @job bJob, 
   	@phase1 bPhase, @phase2 bPhase, @phase3 bPhase, @phase4 bPhase, 
   	@phase5 bPhase, @phase6 bPhase, @phase7 bPhase, @phase8 bPhase,
   	@usage1 bHrs, @usage2 bHrs, @usage3 bHrs, @usage4 bHrs, 
   	@usage5 bHrs, @usage6 bHrs, @usage7 bHrs, @usage8 bHrs, 
   	@equipct1 bJCCType, @equipct2 bJCCType, @equipct3 bJCCType, @equipct4 bJCCType, 
   	@equipct5 bJCCType,	@equipct6 bJCCType, @equipct7 bJCCType, @equipct8 bJCCType, 
   	@revcode1 bRevCode, @revcode2 bRevCode, @revcode3 bRevCode, @revcode4 bRevCode,
   	@revcode5 bRevCode, @revcode6 bRevCode, @revcode7 bRevCode, @revcode8 bRevCode,
   	@phase bPhase, @equipct bJCCType, @emco bCompany, @emgroup bGroup,
   	@equipment bEquip, @revcode bRevCode, @usage bHrs, @lineseq smallint,  @costtypeout bJCCType,
	@errmsg varchar(255)
   
   declare @update_hr_meter bYN, @UseRateOride bYN, @basis char(1),
   	@stdrate bDollar, @alloworide bYN, @postworkunits bYN, @um bUM
   
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
     
   -- read jcco, job, and phases from timesheet header
   select @jcco=JCCo, @job=Job, @phase1=Phase1, @phase2=Phase2, @phase3=Phase3, @phase4=Phase4,
   	@phase5=Phase5, @phase6=Phase6, @phase7=Phase7, @phase8=Phase8
   from dbo.PRRH with (nolock) where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet
   
   -- validate cost types for each equipment in timesheet
   select @emco=min(EMCo) from dbo.PRRQ with (nolock)
   where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet
   while @emco is not null
   	begin
   	select @emgroup=min(EMGroup) from dbo.PRRQ with (nolock)
   	where PRCo=@prco and Crew=@crew and PostDate=@postdate and 
   		SheetNum=@sheet and EMCo=@emco
   	while @emgroup is not null
   		begin
   		select @equipment=min(Equipment) from dbo.PRRQ with (nolock)
   		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and EMGroup=@emgroup
   		while @equipment is not null
   			begin
   			--generate error if equipment is inactive
   		  	if (select Status from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equipment) not in ('A', 'D')
   		  		begin
   		  		select @msg = 'Equipment ' + isnull(@equipment,'') + ' must be active', @rcode = 1
   		  		goto bspexit
   		  		end
   
   			select @lineseq=min(LineSeq) from dbo.PRRQ with (nolock)
   			where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and
   				EMGroup=@emgroup and Equipment=@equipment
   			while @lineseq is not null
   				begin
   				select @usage1=Phase1Usage, @equipct1=Phase1CType, @revcode1=Phase1Rev, 
   					@usage2=Phase2Usage, @equipct2=Phase2CType, @revcode2=Phase2Rev, 
   					@usage3=Phase3Usage, @equipct3=Phase3CType, @revcode3=Phase3Rev, 
   					@usage4=Phase4Usage, @equipct4=Phase4CType, @revcode4=Phase4Rev,
   					@usage5=Phase5Usage, @equipct5=Phase5CType, @revcode5=Phase5Rev, 
   					@usage6=Phase6Usage, @equipct6=Phase6CType, @revcode6=Phase6Rev, 
   					@usage7=Phase7Usage, @equipct7=Phase7CType, @revcode7=Phase7Rev, 
   					@usage8=Phase8Usage, @equipct8=Phase8CType, @revcode8=Phase8Rev
   				from dbo.PRRQ with (nolock)
   				where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and 
   					EMGroup=@emgroup and Equipment=@equipment and LineSeq=@lineseq
   	
   				select @phasenum = 1
   				while @phasenum <= 8
   					begin
   					if @phasenum = 1 select @phase=@phase1, @usage=@usage1, @equipct=@equipct1, @revcode=@revcode1
   					if @phasenum = 2 select @phase=@phase2, @usage=@usage2, @equipct=@equipct2, @revcode=@revcode2
   					if @phasenum = 3 select @phase=@phase3, @usage=@usage3, @equipct=@equipct3, @revcode=@revcode3
   					if @phasenum = 4 select @phase=@phase4, @usage=@usage4, @equipct=@equipct4, @revcode=@revcode4
   					if @phasenum = 5 select @phase=@phase5, @usage=@usage5, @equipct=@equipct5, @revcode=@revcode5
   					if @phasenum = 6 select @phase=@phase6, @usage=@usage6, @equipct=@equipct6, @revcode=@revcode6
   					if @phasenum = 7 select @phase=@phase7, @usage=@usage7, @equipct=@equipct7, @revcode=@revcode7
   					if @phasenum = 8 select @phase=@phase8, @usage=@usage8, @equipct=@equipct8, @revcode=@revcode8
   				
   					if @phase is not null and @usage is not null and @usage<>0
   						begin
   						if @revcode is null
   							begin
   							select @msg = 'Missing revenue code(s).', @rcode=1
   							goto bspexit
   							end
   
   						exec @rcode = bspEMRevCodeValEquip @emco, @emgroup, @equipment, @revcode, 
   							@update_hr_meter output, @UseRateOride output, @basis output,
    							@stdrate output, @alloworide output, @postworkunits output, @um output, 
   							@msg = @errmsg output
   				 		if @rcode <> 0 
   							begin
   							select @msg='Equip Usage: ' + isnull(@errmsg,'')
   							goto bspexit
   							end
   
   						if @equipct is null --issue 23788
   							begin
   							select @msg = 'Missing equipment cost type(s).', @rcode=1
   							goto bspexit
   							end
   	
   				 		exec @rcode = bspPREMUsageCostTypeVal @prco, @equipct, @jcco, @job, @phase, @phase, @costtypeout output, @errmsg output
   				 		if @rcode <> 0 
   							begin
   							select @msg='Equipment Usage: ' + isnull(@errmsg,'')
   							goto bspexit
   							end
   						end
   			
   					select @phasenum = @phasenum + 1
   					end
   
   				select @lineseq=min(LineSeq) from dbo.PRRQ with (nolock)
   				where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and
   					EMGroup=@emgroup and Equipment=@equipment and LineSeq>@lineseq
   			end
   			select @equipment=min(Equipment) from dbo.PRRQ with (nolock)
   			where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and 
   				EMGroup=@emgroup and Equipment>@equipment
   			end
   		select @emgroup=min(EMGroup) from dbo.PRRQ with (nolock)
   		where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo=@emco and EMGroup>@emgroup
   		end
   	select @emco=min(EMCo) from dbo.PRRQ with (nolock)
   	where PRCo=@prco and Crew=@crew and PostDate=@postdate and SheetNum=@sheet and EMCo>@emco
   	end
   
     
   bspexit:
     	if @rcode <> 0 select @msg = isnull(@msg,'') --+ char(13) + char(10) + '[bspPRTSCostTypesVal]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSCostTypesVal] TO [public]
GO
