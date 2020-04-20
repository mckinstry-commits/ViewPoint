SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPSLItemVal]
   /***********************************************************
    * CREATED BY	: MV 07/12/04 - #23834 - return SL Item description
    * MODIFIED BY	:	GP 6/28/10 - #135813 change bSL to varchar(30) 
    *                
    *
    * USAGE:
    * Called by AP Invoice Programs (Recurring, Unapproved, Entry) to
    * return description for a Subcontract Item
    *
    * INPUT PARAMETERS
    *   @slco              SL Co# - this is the same as the AP Co
    *   @sl                Subcontract
    *   @slitem            SL Item#
    *
    * OUTPUT PARAMETERS
    *   @msg               Item description or error message
    *
    * RETURN
    *   0 = success, 1 = error
    ******************************************************/
       (@slco bCompany = 0, @sl varchar(30) = null, @slitem bItem=null, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- get Item information from bSLIT
   select @msg=Description from SLIT with (nolock)
   	where SLCo=@slco and SL=@sl and SLItem=@slitem
   if @@rowcount=0
   	begin
   	select @msg = 'Invalid SL Item!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLItemVal] TO [public]
GO
