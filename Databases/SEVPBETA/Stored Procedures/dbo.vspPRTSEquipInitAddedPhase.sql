SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRTSEquipInitAddedPhase]
	/******************************************************
	* CREATED BY:	mh 6/27/2008 
	* MODIFIED By:  mh 8/22/2008 Issue #129498
	*				mh 11/20/2008 Issue #131156 - Need to encapsulate @revcode in quotes. If @revcode is non-numeric
	*				error occurs without quotes.
	*				mh 04/28/09 Issue #132377 - Do not need to validate equipment cost type against JC.  Just use what 
	*					is in EM and assume it was already validated.
	*
	* Usage:	Called by trigger btPRRHu to add the missing Cost Type
	*			and Revenue code to PRRQ when a Phase is added.
	*
	* Input params:
	*	
	*			@prco - Payroll Company
	*			@crew - Crew
	*			@postdate - Timesheet Post Date
	*			@sheet - Timesheet number
	*			@jcco - Job Company
	*			@job - Job
	*			@phase - Phase being added
	*			@whichphase - Which Phase slot was added (Phase 1 - 8)
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany = null, @crew varchar(10) = null, @postdate bDate = null,
    @sheet smallint = null, @jcco bCompany, @job bJob, @phase bPhase, @whichphase varchar(6), @msg varchar(60) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0

	declare @usage bHrs, @ctype bJCCType, @revcode bRevCode, @seq smallint, @emco bCompany, @equipjcct bJCCType, 
	@costtypeout bJCCType, @crewrevcode bRevCode, @equipment bEquip, @emgroup bGroup, @employee bEmployee, @tsql varchar(8000),
	@openCurs tinyint, @ctvalrcode tinyint

	declare cursPRRQ cursor local fast_forward for
	select EMCo, EMGroup, Equipment, Employee, LineSeq 
	from PRRQ (nolock) 
	where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheet

	open cursPRRQ
	select @openCurs = 1

	fetch next from cursPRRQ into @emco, @emgroup, @equipment, @employee, @seq

	while @@fetch_status = 0
	--while @seq is not null
	begin	 

		--Get RevCode from PRCW
		--If there are multiple Revenue codes defined in PRCW for a piece of equipment picking the top 1.
		--currently no way to match up multiple entries in PRRQ to PRCW so just picking the the first.
		select @crewrevcode = min(RevCode)
		from PRCW (nolock) where PRCo = @prco and Crew = @crew and Employee = @employee
		
		-- init hours values
		select @equipjcct = UsageCostType, @revcode = RevenueCode 
		from EMEM (nolock) where EMCo = @emco and Equipment = @equipment

--		Issue 132377
--		-- validate Phase/Cost Type
--		exec @ctvalrcode = bspPREMUsageCostTypeVal @prco, @equipjcct, @jcco, @job, @phase, @phase, @costtypeout output, @msg output
		
		select @costtypeout = @equipjcct, @usage = 0		

		--If @crewrevcode is something will use it.  Otherwise use @revcode from EMEM
		if @crewrevcode is not null select @revcode=@crewrevcode

		select @tsql = 'Update PRRQ set ' + @whichphase + 'Usage = ' + convert(varchar(9),@usage) + ', ' + @whichphase + 'CType = ' + 
		--convert(varchar(3),@costtypeout) + ', ' + @whichphase + 'Rev = ' + convert(varchar(10),@revcode) + ' Where PRCo = ' + 
		convert(varchar(3),@costtypeout) + ', ' + @whichphase + 'Rev = '+ '''' + convert(varchar(10),@revcode)+ '''' + ' Where PRCo = ' + --131156
		convert(varchar(3),@prco) + ' and Crew = ' + '''' + @crew + '''' + ' and PostDate = ' + '''' + convert(varchar(25),@postdate) + 
		'''' + ' and SheetNum = ' + convert(varchar(3),@sheet) + ' and EMCo= ' + convert(varchar(3),@emco) + ' and EMGroup = ' + 
		convert(varchar(3),@emgroup) + ' and Equipment = ' + '''' + @equipment + '''' + 
		/*' and Employee = ' + convert(varchar(15),@employee)*/
		case when @employee is null then ' and Employee is null' else ' and Employee = ' + convert(varchar(15),@employee) end
		 + ' and LineSeq = ' + convert(varchar(3),@seq)

		exec(@tsql)

		fetch next from cursPRRQ into @emco, @emgroup, @equipment, @employee, @seq
 	end

	vspexit:

	if @openCurs = 1
	begin
		close cursPRRQ
		deallocate cursPRRQ
	end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSEquipInitAddedPhase] TO [public]
GO
