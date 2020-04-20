SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPCValforUpdate    Script Date: 8/28/99 9:35:35 AM ******/
   CREATE  procedure [dbo].[bspPRPCValforUpdate]
   /***********************************************************
    * CREATED BY: GG 06/13/98
    * MODIFIED By : GG 06/13/98
    *              GG 07/22/99 - Change 'inuseby' validation
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				MV 04/27/11 - B-03012 return bPRPC KeyID for attaching ledger update rpts
    *
    * USAGE:
    * Called from the Pay Period Update form to validate and lock
    * a Pay Period prior to loading the Update distribution tables.
    * Returns all available update options.
    *
    * INPUT PARAMETERS
    *   @prco   		PR Company
    *   @prgroup  		PR Group to validate
    *   @prenddate		Pay Period Ending Date
    *
    * OUTPUT PARAMETERS
    *   @status    Pay Period Status 0 = open, 1 = closed
    *   @smjcup		Final SM JC interface flag
    *   @emup		Final EM interface flag
    *   @glup		Final GL interface flag
    *   @errmsg    Error message
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @status tinyint = null output, @smjcup bYN = 'N' output, @emup bYN = 'N' output,
   	 @glup bYN = 'N' output, @KeyID BIGINT OUTPUT,
   	 @errmsg varchar(60) output)
   as

   set nocount on
   
   declare @rcode int, @inuseby bVPUserName
   select @rcode = 0
   
   select @status = Status, @smjcup = JCInterface, @emup = EMInterface, @glup = GLInterface,
	@inuseby = InUseBy, @KeyID = KeyID
   from dbo.bPRPC
   where bPRPC.PRCo = @prco and bPRPC.PRGroup = @prgroup and bPRPC.PREndDate = @prenddate
   if @@rowcount = 0
       begin
       select @errmsg = 'Pay Period not found!', @rcode = 1
       goto bspexit
       end
   -- check if already locked
   if @inuseby is not null and @inuseby <> SUSER_SNAME()
       begin
       select @errmsg = 'Pay Period already in use by ' + @inuseby, @rcode = 1
       goto bspexit
       end
   -- if 'closed', check for available interface options
   if @status = 1 and @smjcup = 'Y' and @emup = 'Y' and @glup = 'Y'
       begin
       select @errmsg = 'All updates for this closed Pay Period have already been run!', @rcode = 1
       goto bspexit
       end
   -- lock Pay Period - will be unlocked after successful interface, another is selected, or form is closed
   update bPRPC set InUseBy = SUSER_SNAME()
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPCValforUpdate] TO [public]
GO
