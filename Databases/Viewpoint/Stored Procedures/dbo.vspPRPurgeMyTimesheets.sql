SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspPRPurgeMyTimesheets]
	/******************************************************
	* CREATED BY:	MH 08/04/2009 
	* MODIFIED By: 
	*
	* Usage:  Purges Timesheets based on parameters.
	*	
	*
	* Input params:
	*
	*	@prco - PR Company
	*	@postedtimesheetYN - Delete posted timesheets flag
	*	@employee - Entry Employee
	*	@thrustartdate - Through Start Date
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@prco bCompany, @postedtimesheetYN bYN, @employee bEmployee,
	@thrustartdate bDate, @errmsg varchar(100) output)

	as 
	set nocount on

	declare @rcode int, @opencurs tinyint, @entryempl bEmployee, @startdate bDate, 
	@sheet int, @status tinyint
   	
	select @rcode = 0

	if @postedtimesheetYN = 'Y'
	begin
		select @status = 4
	end

--test
	select EntryEmployee, StartDate, Sheet
	from PRMyTimesheet 
	where PRCo = @prco  and EntryEmployee = isnull(@employee, EntryEmployee) and
	[Status] = isnull(@status, [Status]) and StartDate <= isnull(@thrustartdate, StartDate)
/*
*/
--end test




	declare bcPRMyTimesheet cursor local fast_forward for
	select EntryEmployee, StartDate, Sheet
	from PRMyTimesheet 
	where PRCo = @prco and EntryEmployee = isnull(@employee, EntryEmployee) and
	[Status] = isnull(@status, [Status]) and StartDate <= isnull(@thrustartdate, StartDate)

	open bcPRMyTimesheet
	select @opencurs = 1

	fetch next from bcPRMyTimesheet into @entryempl, @startdate, @sheet
	while @@fetch_status = 0
	begin

		delete bPRMyTimesheetDetail
		where PRCo = @prco and EntryEmployee = @entryempl and StartDate = @startdate and Sheet = @sheet

		delete bPRMyTimesheet
		where PRCo = @prco and EntryEmployee = @entryempl and StartDate = @startdate and Sheet = @sheet

		fetch next from bcPRMyTimesheet into @entryempl, @startdate, @sheet

	end

	if @opencurs = 1
	begin
		close bcPRMyTimesheet
		deallocate bcPRMyTimesheet
	end
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRPurgeMyTimesheets] TO [public]
GO
