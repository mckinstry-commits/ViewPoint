SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSEquipInit    Script Date: 8/28/99 9:35:39 AM ******/
     CREATE          proc [dbo].[bspPRTSEquipInit]
     /****************************************************************************
      * CREATED BY: EN 3/3/03
      * MODIFIED By :	EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
	  *					mh 9/5/07 - issue ????? - bspPREMUsageCostTypeVal was changed to add @costtypeout output
	  *							param.
	  *					TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
      *
      * USAGE:
      * Initializes equipment entries in bPRRQ based on employee/equipment and
      * equipment-only entries for crew in bPRCW.
      * 
      *  INPUT PARAMETERS
      *   @prco			PR Company
      *   @crew			PR Crew
      *   @postdate		Posting Date
      *	 @sheet			Timesheet Sheet #
      *	 @jcco			Timesheet JC company
      *	 @job			Timesheet Job
      *	 @phase1		Phase1 value to update
      *	 @phase2		Phase2 value to update
      *	 @phase3		Phase3 value to update
      *	 @phase4		Phase4 value to update
      *	 @phase5		Phase5 value to update
      *	 @phase6		Phase6 value to update
      *	 @phase7		Phase7 value to update
      *	 @phase8		Phase8 value to update
      *
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      ****************************************************************************/ 
     (@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
      @sheet smallint = null, @jcco bCompany = null, @job bJob = null, @phase1 bPhase = null,
      @phase2 bPhase = null, @phase3 bPhase = null, @phase4 bPhase = null, @phase5 bPhase = null, 
      @phase6 bPhase = null, @phase7 bPhase = null, @phase8 bPhase = null, @msg varchar(60) output)
     as
     
     set nocount on
     
     declare @rcode int, @retcode int, @numrows int
     
     declare @emco bCompany, @equipment bEquip, @emgroup bGroup, @employee bEmployee, @seq smallint,
     	@usage1 bHrs, @ctype1 bJCCType, @revcode1 bRevCode, @usage2 bHrs, @ctype2 bJCCType, @revcode2 bRevCode,
     	@usage3 bHrs, @ctype3 bJCCType, @revcode3 bRevCode, @usage4 bHrs, @ctype4 bJCCType, @revcode4 bRevCode,
     	@usage5 bHrs, @ctype5 bJCCType, @revcode5 bRevCode, @usage6 bHrs, @ctype6 bJCCType, @revcode6 bRevCode,
     	@usage7 bHrs, @ctype7 bJCCType, @revcode7 bRevCode, @usage8 bHrs, @ctype8 bJCCType, @revcode8 bRevCode,
     	@equipjcct bJCCType, @revcode bRevCode, @crevcode bRevCode, @totalusage bHrs, @costtypeout bJCCType, @errmsg varchar(200)
     
     select @rcode = 0, @retcode = 0
     
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
     -- validate JC company
     if @jcco is null
     	begin
     	select @msg = 'Missing JC Company!', @rcode = 1
     	goto bspexit
     	end
     -- validate Job
     if @job is null
     	begin
     	select @msg = 'Missing Job!', @rcode = 1
     	goto bspexit
     	end


     -- spin through employees in PRCW
     select @seq = min(Seq) from PRCW 
     where PRCo=@prco and Crew=@crew and EMCo is not null and Equipment is not null
     WHILE @seq is not null
     	BEGIN
     	--read emco, equipment, emgroup, and employee values
     	select @emco=EMCo, @equipment=Equipment, @emgroup=EMGroup, @employee=Employee, @crevcode=RevCode from PRCW 
     	where PRCo=@prco and Crew=@crew and Seq=@seq
     	-- init hours values
     	select @equipjcct = UsageCostType, @revcode = RevenueCode from EMEM where EMCo = @emco and Equipment = @equipment
     	
		--Return if Equipment Change in progress for New Equipment Code - 126196
		exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @msg output
		If @rcode = 1
		begin
			  goto bspexit
		end

     	if @phase1 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase1, @phase1, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage1=0, @ctype1=@equipjcct, @revcode1=@revcode
     		if @crevcode is not null select @revcode1=@crevcode
     		end
     	else
     		select @usage1=null, @ctype1=null, @revcode1=null
     
     	if @phase2 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase2, @phase2, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage2=0, @ctype2=@equipjcct, @revcode2=@revcode
     		if @crevcode is not null select @revcode2=@crevcode
     		end
     	else
     		select @usage2=null, @ctype2=null, @revcode2=null
     
     	if @phase3 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase3, @phase3, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage3=0, @ctype3=@equipjcct, @revcode3=@revcode
     		if @crevcode is not null select @revcode3=@crevcode
     		end
     	else
     		select @usage3=null, @ctype3=null, @revcode3=null
     
     	if @phase4 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase4, @phase4, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage4=0, @ctype4=@equipjcct, @revcode4=@revcode
     		if @crevcode is not null select @revcode4=@crevcode
     		end
     	else
     		select @usage4=null, @ctype4=null, @revcode4=null
     
     	if @phase5 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase5, @phase5, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage5=0, @ctype5=@equipjcct, @revcode5=@revcode
     		if @crevcode is not null select @revcode5=@crevcode
     		end
     	else
     		select @usage5=null, @ctype5=null, @revcode5=null
     
     	if @phase6 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase6, @phase6, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage6=0, @ctype6=@equipjcct, @revcode6=@revcode
     		if @crevcode is not null select @revcode6=@crevcode
     		end
     	else
     		select @usage6=null, @ctype6=null, @revcode6=null
     
     	if @phase7 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase7, @phase7, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage7=0, @ctype7=@equipjcct, @revcode7=@revcode
     		if @crevcode is not null select @revcode7=@crevcode
     		end
     	else
     		select @usage7=null, @ctype7=null, @revcode7=null
     
     	if @phase8 is not null 
     		begin
    		exec @retcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase8, @phase8, @costtypeout output, @errmsg output
    		--if @retcode <> 0 select @rcode=5
     		select @usage8=0, @ctype8=@equipjcct, @revcode8=@revcode
     		if @crevcode is not null select @revcode8=@crevcode
     		end
     	else
     		select @usage8=null, @ctype8=null, @revcode8=null
     
   		-- compute total usage
   		select @totalusage=@usage1+@usage2+@usage3+@usage4+@usage5+@usage6+@usage7+@usage8
   
     	-- insert employee entry into bPRRQ
     	insert bPRRQ (PRCo, Crew, PostDate, SheetNum, EMCo, EMGroup, Equipment, LineSeq, Employee, 
     		Phase1Usage, Phase1CType, Phase1Rev, Phase2Usage, Phase2CType, Phase2Rev, 
     		Phase3Usage, Phase3CType, Phase3Rev, Phase4Usage, Phase4CType, Phase4Rev, 
     		Phase5Usage, Phase5CType, Phase5Rev, Phase6Usage, Phase6CType, Phase6Rev, 
     		Phase7Usage, Phase7CType, Phase7Rev, Phase8Usage, Phase8CType, Phase8Rev, TotalUsage)
     	values (@prco, @crew, @postdate, @sheet, @emco, @emgroup, @equipment, @seq, @employee,
     		@usage1, @ctype1, @revcode1, @usage2, @ctype2, @revcode2,
     		@usage3, @ctype3, @revcode3, @usage4, @ctype4, @revcode4,
     		@usage5, @ctype5, @revcode5, @usage6, @ctype6, @revcode6,
     		@usage7, @ctype7, @revcode7, @usage8, @ctype8, @revcode8, @totalusage)
     
     	-- get next bPRCW entry
     	select @seq = min(Seq) from PRCW
     	where PRCo=@prco and Crew=@crew and EMCo is not null and Equipment is not null and Seq>@seq
     	END
     
     
     bspexit:
     	--if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRTSEquipInit]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSEquipInit] TO [public]
GO
