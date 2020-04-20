SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmplLeaveVal    Script Date: 6/27/2003 2:29:05 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspPREmplLeaveVal    Script Date: 8/28/99 9:35:32 AM ******/
   CREATE   proc [dbo].[bspPREmplLeaveVal]
   (@prco bCompany, @employee bEmployee, @leavecode bLeaveCode, @msg varchar(60) output)
   /***********************************************************
    * CREATED BY: EN 1/22/98
    * MODIFIED By : EN 6/22/99
    *               EN 1/31/00 - used to return empl/leave info but removed that code into bspPRELAmtsGet and bspPRELStatsGet
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				EN 11/09/2009 #131962  Corrected to use tables as opposed to views for security clearance on employees
    *
    * Usage:
    *	Validate an employee/leave code combination to PREL.
    *
    * Input params:
    *	@prco		PR company
    *	@employee	Employee Code to validate
    *	@leavecode	Leave Code to validate
    *
    * Output params:
    *	@msg		Leave code description or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   as
   set nocount on
   declare @rcode int
   
   select @rcode = 0
   
   /* check required input params */
   
   /* validate employee */
   if @employee is null
   	begin
   	select @msg = 'Missing Employee.', @rcode = 1
   	goto bspexit
   	end
   if not exists(select * from dbo.bPREH with (nolock) where PRCo=@prco and Employee=@employee)
   	begin
   	select @msg = 'Invalid Employee.', @rcode = 1
   	goto bspexit
   	end
   
   /* validate leave code */
   if @leavecode is null
   	begin
   	select @msg = 'Missing Leave Code.', @rcode = 1
   	goto bspexit
   	end
   if not exists(select * from dbo.bPRLV with (nolock) where PRCo=@prco and LeaveCode=@leavecode)
   	begin
   	select @msg = 'Invalid Leave Code.', @rcode = 1
   	goto bspexit
   	end
   
   /* validate employee/leave code combination */
   if not exists(select * from dbo.bPREL with (nolock) where PRCo=@prco and Employee=@employee and LeaveCode=@leavecode)
   	begin
   	select @msg = 'Employee/Leave Code has not been set up.', @rcode = 1
   	goto bspexit
   	end
   
--	declare @availbaldate bDate, @cap1date bDate, @cap2date bDate
--
--	select @availbaldate = AvailBalDate, @cap1date = Cap1Date, @cap2date = Cap2Date
--	from PREL (nolock) where PRCo = @prco and Employee = @employee and LeaveCode = @leavecode
--
--	if @availbaldate is null or @cap1date is null or @cap2date is null
--	begin
--		select @msg = 'Employee/Leave Reset dates have not been entered.', @rcode = 1
--		goto bspexit
--	end  
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmplLeaveVal] TO [public]
GO
