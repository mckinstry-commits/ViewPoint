SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREligibleDateVal    Script Date: 8/28/99 9:33:18 AM ******/
   CREATE  proc [dbo].[bspPREligibleDateVal]
   
   /***********************************************************
    * CREATED BY: EN 2/14/98
    * MODIFIED By : EN 4/3/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    *
    * Usage:
    *	Compare activity date against effective date for a specified
    *	Employee/Leave Code and return a warning message if activity
    *	date is earlier than the effective date.
    *
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *	@leavecode	Leave Code
    *	@actdate	Activity Date
    *
    * Output params:
    *	@msg		Error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/ 
   (@prco bCompany, @empl bEmployee, @leavecode bLeaveCode, @actdate bDate,
   @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @eligdate bDate
   
   select @rcode = 0
   
   /* check required input params */	
   
   if @empl is null
   	begin
   	select @msg = 'Missing Employee.', @rcode = 1
   	goto bspexit
   	end
   if @leavecode is null
   	begin
   	select @msg = 'Missing Leave Code.', @rcode = 1
   	goto bspexit
   	end
   if @actdate is null
   	begin
   	select @msg = 'Missing activity date.', @rcode = 1
   	goto bspexit
   	end
   		
   if not exists(select * from PREH where PRCo=@prco and Employee=@empl)
   	begin
   	select @msg = 'Not a valid Employee', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from PRLV where PRCo=@prco and LeaveCode=@leavecode)
   	begin
   	select @msg = 'Not a valid Leave Code.', @rcode = 1
   	goto bspexit
   	end
   
   select @eligdate=EligibleDate from PREL
   where PRCo=@prco and Employee=@empl and LeaveCode=@leavecode
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Employee/Leave Code combination.', @rcode = 1
   	goto bspexit
   	end
   	
   if @actdate<@eligdate
   	begin
   	select @msg = 'Date selected is earlier than eligible date.', @rcode = 1
   	end
   	
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREligibleDateVal] TO [public]
GO
