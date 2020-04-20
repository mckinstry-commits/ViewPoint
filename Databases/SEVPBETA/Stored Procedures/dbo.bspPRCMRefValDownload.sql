SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRCMRefValDownload]
   /***********************************************************
   * Created: GG 08/09/02 - #17017
   * Modified:
   *
   * Usage:
   *   Validates CM Reference within existing Pay Period period
   *	prior to download.  Returns Paid Date for default values.
   *
   * Inputs:
   *   @prco      		PR Company#
   *   @prgroup		PR Group
   *	@prenddate		PR Ending Date
   *   @cmref     		CM Reference to validate
   *
   * Outputs:
   *	@paiddate		Paid Date
   *   @msg     		message if invalid
   *
   * Return code:
   *   0 = success, 1 = fail
   *  
   *****************************************************/
   
   	@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	@cmref bCMRef = null, @paiddate bDate output, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if not exists(select 1 from bPRPC where PRCo = @prco and PRGroup = @prgroup
   		and PREndDate = @prenddate)
   	begin
   	select @msg = 'Invalid Pay Period!', @rcode = 1
   	goto bspexit
   	end
   if @cmref is null
   	begin
   	select @msg = 'Missing CM Reference!', @rcode = 1
   	goto bspexit
   	end
   
   -- see if CM Reference assigned in Employee Sequence Control, get first occurence
   select top 1 @paiddate = PaidDate
   from bPRSQ
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and PayMethod = 'E' and CMRef = @cmref
   if @@rowcount = 0
   	begin
    	select @msg = 'This CM Reference has not been assigned to any earnings in the Pay Period.', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCMRefValDownload] TO [public]
GO
