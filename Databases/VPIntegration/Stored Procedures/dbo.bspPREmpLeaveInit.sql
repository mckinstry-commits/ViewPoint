SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmpLeaveInit    Script Date: 8/28/99 9:35:32 AM ******/
   CREATE   procedure [dbo].[bspPREmpLeaveInit]
   /***********************************************************
    * CREATED BY: EN 12/08/97
    * MODIFIED By : EN 12/08/97
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				mh 03/23/09 - issue 131977  Populate Cap1/Cap2/AvailBalDate with elig date.
    *
    * USAGE:
    * For a specified leave code, insert PREL entries which don't already
    * exist for all/active employees in a specified PR Co and Group.
    *
    *  INPUT PARAMETERS
    *   @prco	PR company number
    *   @prgroup	PR group
    *   @empsel	Employees to include (null=All, 'Y'=Active only)
    *   @leavecode	Leave Code being initialized
    *   @eligdate	Date to use for eligible date
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *******************************************************************/
   (@prco bCompany, @prgroup bGroup, @empsel varchar(1),
   	@leavecode bLeaveCode, @eligdate bDate,
    	@msg varchar(90) output)
   as
   set nocount on
   
   declare @rcode int, @PREHopened tinyint, @employee bEmployee
   
   select @rcode=0, @msg='Mission Accomplished!'
   if @empsel='' select @empsel=null
   
   /* initialize open cursor flag to false */
   select @PREHopened = 0
   
   /* initialize cursor for PR Employee Header */
   declare bcPREH cursor
   	for select Employee from bPREH
   	where PRCo=@prco and PRGroup=@prgroup and ActiveYN=isnull(@empsel,ActiveYN)
   	for read only
   		 /* open cursor */
   open bcPREH
   
   /* set open cursor flag to true */ select @PREHopened = 1
   
   /* loop through all eligible employees */
   employee_loop:
   	fetch next from bcPREH into @employee
   
   	if @@fetch_status <> 0 goto bspexit
   
   	if not exists(select * from bPREL where PRCo=@prco and Employee=@employee 
   			and LeaveCode=@leavecode)
   		begin
   			insert into PREL (PRCo,Employee,LeaveCode,EligibleDate,FixedUnits,FixedFreq,
			Cap1Freq,Cap1Max,Cap1Accum,Cap1Date,Cap2Freq,Cap2Max,Cap2Accum,Cap2Date,
			AvailBalFreq,AvailBalMax,CarryOver,AvailBal,AvailBalDate,InUseMth,InUseBatchId,Notes) 
   			values (@prco, @employee, @leavecode, @eligdate, null, null, null, null, 0,
   			@eligdate, null, null, 0, @eligdate, null, null, null, 0, @eligdate, null, null, null)
   		
			if @@rowcount = 0
   			begin
   			select @msg = 'Error occurred during initialization!'
   			goto bspexit
   			end
   		end
   		
   	goto employee_loop
   	
   bspexit:
   	if @PREHopened = 1
   		begin
   		close bcPREH
   		deallocate bcPREH
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmpLeaveInit] TO [public]
GO
