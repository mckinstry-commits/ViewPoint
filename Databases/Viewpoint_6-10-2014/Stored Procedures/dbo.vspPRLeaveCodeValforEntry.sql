SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRLeaveCodeValforEntry]
/************************************************************************
* CREATED:	mh 10/4/2006    
* MODIFIED: mh 09/10/2006 - Issue 129377.  Raising error if Accum1, Accum2 and AvailBal dates 
*							are null.   
*			mh Issue 12/15/2008 Issue 131422.  Amend 129377, do not raise reset error if Accum1,
*					Accum2, and AvailBal limits are zero.  Zero means there is no limit.
*			EN 11/09/2009 #131962  Corrected to use tables as opposed to views for security clearance on employees
*
* Purpose of Stored Procedure
*
*   Validate Leave Code for PR Leave Entry and check that code
*	is not in use.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    
    (@prco bCompany, @leavecode bLeaveCode, @batchid bBatchID, @employee bEmployee, 
	@um bUM output, @accum1Limit bHrs output, @accum2Limit bHrs output, @availbalmax bHrs output,
    @accum1Freq bFreq output, @accum2Freq bFreq output, @availbalfreq bFreq output,
    @accum1Date bDate output, @accum2Date bDate output, @availbaldate bDate output,
    @accum1 bHrs output, @accum2 bHrs output, @availbal bHrs output, @msg varchar(100) output)

as
set nocount on

    declare @rcode int, @leavecodedesc varchar(100)

    select @rcode = 0

	/* validate leave code */
	if @leavecode is null
	begin
		select @msg = 'Missing Leave Code.', @rcode = 1
		goto vspexit
	end

	--Check that LeaveCode exists and if it does get UM. This is what we originally
	--did with a call to bspPRLeaveCodeVal
	select @um = UM, @leavecodedesc = Description from dbo.bPRLV with (nolock) where PRCo = @prco and LeaveCode = @leavecode
	if @@rowcount = 0
   	begin
   		select @msg = 'Not a valid Leave Code', @rcode = 1
		goto vspexit
   	end

--	--Check Employee/LeaveCode has been set up.
--	exec @rcode = bspPREmplLeaveVal @prco, @employee, @leavecode, @msg output
--	if @rcode = 1
--	begin
--		goto vspexit
--	end

	if not exists(select 1 from dbo.bPREL with (nolock) where PRCo=@prco and Employee=@employee and LeaveCode=@leavecode)
	begin
		select @msg = 'Employee/Leave Code has not been set up.', @rcode = 1
		goto vspexit
	end
   
	--Check LeaveCode/Employee is not in another batch.  We used to make this check
	--when the record was saved.  Why not check it up front.
	exec @rcode = bspPRELInUseVal @prco, @batchid, @employee, @leavecode, @msg output
	if @rcode = 1
	begin
		goto vspexit
	end

	--Leave code exists and LeaveCode/Employee combo not in another batch.  Get the stats.
	exec @rcode = bspPRELStatsGet @prco, @employee, @leavecode,
     @accum1Limit output, @accum2Limit output, @availbalmax output,
     @accum1Freq output, @accum2Freq output, @availbalfreq output,
     @accum1Date output, @accum2Date output, @availbaldate output,
     @msg output

	--Issue 129377
	--if @availbaldate is null or @accum1Date is null or @accum2Date is null

	if (@availbaldate is null and isnull(@availbalmax,0) <> 0) or 
		(@accum1Date is null and isnull(@accum1Limit,0) <> 0) or 
		(@accum2Date is null and isnull(@accum2Limit,0) <> 0)
	begin
		select @msg = 'Employee/Leave Reset dates have not been entered in PR Employee Leave.', @rcode = 1
		goto vspexit
	end  

	select @accum1 = Cap1Accum, @accum2 = Cap2Accum, @availbal = AvailBal
   	from dbo.bPREL with (nolock) where PRCo=@prco and Employee=@employee and LeaveCode=@leavecode

	if @rcode = 0
	begin
		select @msg = @leavecodedesc
	end
	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRLeaveCodeValforEntry] TO [public]
GO
