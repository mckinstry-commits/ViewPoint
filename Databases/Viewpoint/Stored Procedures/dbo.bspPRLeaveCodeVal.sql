SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLeaveCodeVal    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE  proc [dbo].[bspPRLeaveCodeVal]
   (@prco bCompany, @leavecode bLeaveCode, @um bUM output, @acctype varchar(1) output, @fixedunits bHrs output,
    @fixedfreq bFreq output, @cap1max bHrs output, @cap1freq bFreq output, @cap2max bHrs output, @cap2freq bFreq output,
    @availbalmax bHrs output, @availbalfreq bFreq output, @carryover bHrs output, @msg varchar(60) output)
   /***********************************************************
    * CREATED BY: EN 12/10/97
    * MODIFIED By : EN 4/3/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	Validate a leave code
    *
    * Input params:
    *	@prco		PR company
    *	@leavecode	Leave Code to validate
    *
    * Output params:
    *	@um		Unit of measure assigned to the leave code
    *	@acctype	'F' if accrual is fixed amount, 'R' if rate of earnings
    *  @fixedunits Fixed accrual units
    *  @fixedfreq  Fixed accrual frequency
    *  @cap1max    Cap 1 maximum amount limit
    *  @cap1freq   Cap 1 reset frequency
    *  @cap2max    Cap 2 maximum amount limit
    *  @cap2freq   Cap 2 reset frequency
    *  @availbalmax    Available balance maximum amount limit
    *  @availbalfreq   Available balance frequency
    *  @carryover  Available balance carryover amount
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
   if @leavecode is null
   	begin
   	select @msg = 'Missing Leave Code.', @rcode = 1
   	goto bspexit
   	end
   
   /* validate */
   select @msg=Description, @um=UM, @acctype=AccType, @fixedunits=FixedUnits, @fixedfreq=FixedFreq, @cap1max=Cap1Max,
    @cap1freq=Cap1Freq, @cap2max=Cap2Max, @cap2freq=Cap2Freq, @availbalmax=AvailBalMax, @availbalfreq=AvailBalFreq,
    @carryover=CarryOver from PRLV where PRCo=@prco and LeaveCode=@leavecode
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Leave Code', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLeaveCodeVal] TO [public]
GO
