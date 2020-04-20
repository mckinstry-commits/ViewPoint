SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREndDateValforAutoLeave]
/************************************************************************
* CREATED:	mh 10/23/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Used in PRAutoLeave
*
*   In 5.x we validated the Pay Period End Dates via validation procedures
*	in DDFI.  In code we then validated Pay Period against the Batch Month
*	we are in on the lost focus event of the Pay Period text boxes and again
*	when calling the Post Auto Leave routine.
*
*	For 6.x I combined the procedures and added both Pay Period End Dates to the
*	same update group.  Also combining this with the bspPRAutoLeavePosting.  The
*	calls to bspPREndDateVal will be redudent but the caled to bspPRPeriodMonthCheck
*	was being called again prior to the AutoLeavePosting sp.  
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

   (@prco bCompany, @mth bMonth, @prgroup bGroup, @begpayperenddate bDate = null, @endpayperenddate bDate = null, 
	@statusopt varchar(1),  @deleteyn bYN, @periodchkerr int output, @periodmsg varchar(200) output, 
	@msg varchar(200) output)
as
set nocount on

    declare @rcode int

    select @rcode = 0, @periodchkerr = 0

	--First validate pay periods, once for the beginning pay period end date then again
	--for the ending pay period end date

	exec @rcode = bspPREndDateVal @prco, @prgroup, @begpayperenddate, @statusopt, @msg output

	if @rcode = 1
		goto vspexit

	if @endpayperenddate is not null
	begin
		exec @rcode = bspPREndDateVal @prco, @prgroup, @endpayperenddate, @statusopt, @msg output
		if @rcode = 1
			goto vspexit
	end
	else
		goto vspexit

	--pay period ending dates are ok, now do the Period Month Check

	exec @rcode = bspPRPeriodMonthCheck @prco, @mth, @prgroup, @begpayperenddate,
		@endpayperenddate, @deleteyn, @msg output

	--Standards will evaluate @rcode as part of validation.  bspPeriodMonthCheck can return 0,1,5.  5 is
	--used to give the user some kind of warning but allow them to proceed.  Passing the return code back
	--as an output parameter to a hidden form field that can be evaluated.
	select @periodchkerr = @rcode, @periodmsg = @msg

vspexit:
 
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPREndDateValforAutoLeave] TO [public]
GO
