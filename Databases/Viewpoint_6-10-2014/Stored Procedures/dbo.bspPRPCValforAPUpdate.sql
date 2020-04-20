SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPCValforAPUpdate    Script Date: 8/28/99 9:35:35 AM ******/
   CREATE  procedure [dbo].[bspPRPCValforAPUpdate]
   /***********************************************************
    * CREATED BY: GG 08/14/98
    * MODIFIED By : GG 08/14/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
	*				mh 3/4/2008 - Issue 127104 - Change @errmsg from varchar(60) to varchar(1000).
	*								Error message was being truncated.
    *
    * USAGE:
    * Called from the Pay Period AP Update form to validate
    * a Pay Period prior to performing the update.
    *
    * INPUT PARAMETERS
    *   @prco   		PR Company
    *   @prgroup  		PR Group to validate
    *   @prenddate		Pay Period Ending Date
    *
    * OUTPUT PARAMETERS
    *   @status    	Pay Period Status 0 = open, 1 = closed
    *   @errmsg    Error message
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @status tinyint = null output, @errmsg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @inuseby bVPUserName, @apinterface bYN
   select @rcode = 0
   
   select @status = Status, @apinterface = APInterface, @inuseby = InUseBy
   from bPRPC
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
       begin
       select @errmsg = 'Pay Period not found!', @rcode = 1
       goto bspexit
       end
   -- check if already locked
   if @inuseby is not null
       begin
       select @errmsg = 'Pay Period already in use by ' + @inuseby, @rcode = 1
       goto bspexit
       end
   -- if 'closed', check for available interface options
   if @status = 1 and @apinterface = 'Y'
       begin
       select @errmsg = 'The final AP update for this closed Pay Period has already been run!', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPCValforAPUpdate] TO [public]
GO
