SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSPClear    Script Date: 8/28/99 9:35:39 AM ******/
   CREATE  proc [dbo].[bspPRSPClear]
   /****************************************************************************
    * CREATED BY: EN 03/12/98
    * MODIFIED By : EN 03/12/98
    *				GG 09/15/01 - Added input parameters for Employee and PaySeq to allow
    *							stub info for a single payment to be cleared.
    *				EN 2/22/08 - 25357  Added options to set and clear PRPC_InUseBy flag to reserve pay period for check print.
	*								Also added option to return an error if the pay period is currently reserved by another user. 
    *
    * USAGE:
    * Clears entries for a specified PRCo/PRGroup/PREndDate from PRSP and PRSX.
    * 
    *  INPUT PARAMETERS
    *   @prco			PR Company
    *   @prgroup		PR Group
    *   @prenddate		PR Period Ending Date
    *	 @employee		Employee - if null, all employees w/in Pay Period
    *	 @payseq		Pay Seq	- if null, all pay seq#s
	*	@clearinuseby	= 'Y' if user requested that PRPC_InUseBy flag gets cleared
	*	@setinuseby		= 'Y' if calling program needs PRPC_InUseBy set for this user
	*	@errorifinuse	= 'Y' to abort clear and return error if pay period is already in use
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************/ 
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @employee bEmployee = null, @payseq tinyint = null, @clearinuseby bYN,
	 @setinuseby bYN, @errorifinuse bYN, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @numrows int, @inuseby bVPUserName
   
   select @rcode = 0
   
   -- validate input parameters
   if @prco is null or @prgroup is null or @prenddate is null
   	begin
   	select @msg = 'Missing PR Co#, PR Group, and/or PR Ending Date', @rcode = 1
   	goto bspexit
   	end
 
   -- issue 25357  get current PRPC_InUseBy value  
   select @inuseby = isnull(InUseBy,'') from dbo.bPRPC where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

   -- issue 25357  if option to clear the InUseBy flag is used, it is not necessary to attempt to set or check InUseBy
   if @clearinuseby <> 'Y'
	begin
	-- issue 25357  Option to attempt setting InUseBy if it is currently not set and continue on to stub delete
	if @setinuseby = 'Y' and @inuseby = ''
		begin
		update dbo.bPRPC set InUseBy = SUSER_SNAME() where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		if @@rowcount = 0
			begin
			select @msg = 'Unable to reserve the pay period for printing checks.', @rcode = 1
			goto bspexit
			end	
		goto deletecheckdata
		end

	-- issue 25357  abort if pay period is already In Use with option to return error
	if @inuseby <> '' and @inuseby <> SUSER_SNAME()
		begin
		select @rcode = 5 --code 5 will be returned if option to return error (@errorifinuse) was not selected
		if @errorifinuse = 'Y' select @msg = 'This pay period has been reserved by user ' + @inuseby + '.  Please try again later.', @rcode = 1
		goto bspexit
		end
	end

   deletecheckdata:

   -- delete stub detail
   select @numrows =  count(*) from bPRSX
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and Employee = isnull(@employee, Employee) and PaySeq = isnull(@payseq, PaySeq)
   if @numrows > 0
   	begin
   	delete from bPRSX
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   		and Employee = isnull(@employee, Employee) and PaySeq = isnull(@payseq, PaySeq)
   	if @@rowcount <> @numrows
   	 	begin
   		select @msg = 'Unable to remove all PR Check Stub Detail entries.', @rcode = 1
   		goto bspexit
   		end	
   	end
   -- delete stub header
   select @numrows =  count(*) from bPRSP
   where PRCo = @prco and PRGroup=@prgroup and PREndDate=@prenddate
   	and Employee = isnull(@employee, Employee) and PaySeq = isnull(@payseq, PaySeq)
   if @numrows > 0
   	begin
   	delete from bPRSP
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   		and Employee = isnull(@employee, Employee) and PaySeq = isnull(@payseq, PaySeq)
   	if @@rowcount <> @numrows
   		begin
   		select @msg = 'Unable to remove all PR Check Stub Header entries.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   -- issue 25357  option to clear PRPC_InUseBy flag
   if @clearinuseby = 'Y' 
	begin
	update dbo.bPRPC set InUseBy = null where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	if @@rowcount = 0
   	 	begin
   		select @msg = 'Unable to un-reserve this pay period for the check print.', @rcode = 1
   		goto bspexit
   		end	
	end


   bspexit:
   	--if @rcode <> 0 --select @msg = @msg + char(13) + char(10) + '[bspPRSPClear]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSPClear] TO [public]
GO
