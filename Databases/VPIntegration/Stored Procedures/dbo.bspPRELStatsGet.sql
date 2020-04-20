SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRELStatsGet    Script Date: 8/28/99 9:35:32 AM ******/
    CREATE  proc [dbo].[bspPRELStatsGet]
    (@prco bCompany, @employee bEmployee, @leavecode bLeaveCode,
     @cap1max bHrs output, @cap2max bHrs output, @availbalmax bHrs output,
     @cap1freq bFreq output, @cap2freq bFreq output, @availbalfreq bFreq output,
     @cap1date bDate output, @cap2date bDate output, @availbaldate bDate output,
     @msg varchar(60) output)
    /***********************************************************
     * CREATED BY: EN 1/31/00
     * MODIFIED By : EN 1/31/00
     *               EN 2/17/00 - modify to check for reset date overrides in bPRAB
     *               EN 2/22/00 - removed reset date override deciding that it should only be done in bspPRLeaveResetPost
	 *				 MH 04/24/09 - Issue 131962 - make sure we are using the table, not the view.
     *
     * Usage:
     *	Return accumulator and available balance information from bPRLV and bPREL overrides.
     *  Also checks for reset date overrides in bPRAB in case any batches contain reset entries.
     *
     * Input params:
     *	@prco		PR company
     *	@employee	Employee Code to validate
     *	@leavecode	Leave Code to validate
     *
     * Output params:
     *	@cap1max	Accrual accumulator 1 limit
     *	@cap2max	Accrual accumulator 2 limit
     *	@availbalmax	Available balance limit
     *	@cap1freq	Accrual accumulator 1 reset frequency
     *	@cap2freq	Accrual accumulator 2 reset frequency
     *	@availbalfreq	Available balance reset frequency
     *	@cap1date	Last reset date of accrual accumulator 1
     *	@cap2date	Last reset date of accrual accumulator 2
     *	@availbaldate	Last reset date of available balance
     *	@msg		Leave code description or error message
     *
     * Return code:
     *	0 = success, 1 = failure
     ************************************************************/
    as
    set nocount on
    declare @rcode int, @PRLVcap1freq bFreq, @PRLVcap1max bHrs, @PRLVcap2freq bFreq,
        @PRLVcap2max bHrs, @PRLVavailbalfreq bFreq, @PRLVavailbalmax bHrs
   
    select @rcode = 0
   
    /* check required input params */
   
    /* validate employee */
    if not exists(select 1 from bPREH where PRCo=@prco and Employee=@employee)
    	begin
    	select @msg = 'Invalid Employee.', @rcode = 1
    	goto bspexit
    	end
   
    /* get info from PRLV */
    select @PRLVcap1freq=Cap1Freq, @PRLVcap1max=Cap1Max, @PRLVcap2freq=Cap2Freq,
        @PRLVcap2max=Cap2Max, @PRLVavailbalfreq=AvailBalFreq, @PRLVavailbalmax=AvailBalMax
    	from bPRLV where PRCo=@prco and LeaveCode=@leavecode
    if @@rowcount=0
    	begin
    	select @msg = 'Invalid Leave Code.', @rcode = 1
    	goto bspexit
    	end
   
    /* get overrides from PREL */
    select @cap1freq = isnull(Cap1Freq,@PRLVcap1freq), @cap1max = isnull(Cap1Max,@PRLVcap1max),
    	@cap2freq = isnull(Cap2Freq,@PRLVcap2freq), @cap2max = isnull(Cap2Max,@PRLVcap2max),
    	@availbalfreq = isnull(AvailBalFreq,@PRLVavailbalfreq),
        @availbalmax = isnull(AvailBalMax,@PRLVavailbalmax),
        @cap1date = Cap1Date, @cap2date = Cap2Date, @availbaldate = AvailBalDate
    	from bPREL where PRCo = @prco and Employee = @employee and LeaveCode = @leavecode
    if @@rowcount=0
    	begin
    	select @msg = 'Employee/Leave Code has not been set up.', @rcode = 1
    	goto bspexit
    	end
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRELStatsGet] TO [public]
GO
