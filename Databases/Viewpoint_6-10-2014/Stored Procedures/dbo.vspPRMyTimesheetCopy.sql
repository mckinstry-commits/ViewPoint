SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRMyTimesheetCopy]
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By:	GF 09/06/2010 - issue #141031 use vfDateOnly function
	*               EricV 08/23/11 - TK-07782 - Added SMCostType.
	*
	* Usage:  Copy's a timesheet
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@prco bCompany, @userid bVPUserName, @entryemployee bEmployee, @sourcestartdate bDate, 
	@sourcesheet int, @includehrsyn bYN, @deststartdate bDate, @destsheet int, @msg varchar(100) output

	as 
	set nocount on
	declare @rcode int
	
   	declare @createdon bDate
   	----#141031
	set @createdon = dbo.vfDateOnly()

	select @rcode = 0

	begin transaction

	if @prco is null
	begin
		select @msg = 'Missing PR Company', @rcode = 1
		goto vspexit
	end

	if @userid is null
	begin
		select @msg = 'Missing User ID', @rcode = 1
		goto vspexit
	end

	if @entryemployee is null
	begin
		select @msg = 'Missing Entry Employee', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from PRMyTimesheet 	where PRCo = @prco and EntryEmployee = @entryemployee and 
		StartDate = @sourcestartdate and Sheet = @sourcesheet)
	begin
		insert PRMyTimesheetDetail (PRCo, EntryEmployee, StartDate, Sheet, Seq, Employee, JCCo, Job, 
		PhaseGroup, Phase, EarnCode, Craft, Class, Shift, DayOne, DayTwo, DayThree, DayFour, 
		DayFive, DaySix, DaySeven, CreatedBy, CreatedOn, Approved, LineType, SMCo, WorkOrder, Scope, PayType, SMCostType)

		select @prco, @entryemployee, @deststartdate, @destsheet, Seq, Employee, JCCo, Job, PhaseGroup,
		Phase, EarnCode, Craft, Class, Shift, 
		case @includehrsyn when 'Y' then DayOne else null end, 
		case @includehrsyn when 'Y' then DayTwo else null end, 
		case @includehrsyn when 'Y' then DayThree else null end, 
		case @includehrsyn when 'Y' then DayFour else null end, 
		case @includehrsyn when 'Y' then DayFive else null end, 
		case @includehrsyn when 'Y' then DaySix else null end, 
		case @includehrsyn when 'Y' then DaySeven else null end,
		@userid, convert(smalldatetime, @createdon), 'N', LineType, SMCo, WorkOrder, Scope, PayType, SMCostType 
		from dbo.PRMyTimesheetDetail (nolock)
		where PRCo = @prco and EntryEmployee = @entryemployee and StartDate = @sourcestartdate and
		Sheet = @sourcesheet 
	end
	else
	begin
		select @msg = 'Unable to copy Timesheet', @rcode = 1
	end

	vspexit:

	if @rcode = 0
	begin
		commit transaction
	end
	else
	begin
		rollback transaction
	end

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetCopy] TO [public]
GO
