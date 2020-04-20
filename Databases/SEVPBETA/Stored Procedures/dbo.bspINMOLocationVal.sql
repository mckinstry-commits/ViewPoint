SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspINMOLocationVal]
   /********************************************************
   	Created By: RM 02/21/02
   
   	Usage: used in Material Order Entry to validate Location
   
   
   
   
   
   
   
   *********************************************************/
   (@co bCompany,@location bLoc,@msg varchar(255) output)
   as
   
   declare @rcode int,@active bYN
   
   select @rcode=0
   
   
   
   select @active=Active,@msg=Description from INLM where INCo=@co and @location=Loc
   if @@rowcount=0
   begin
   	select @msg='Invalid IN Location.',@rcode=1
   	goto bspexit
   end
   
   if @active='N'
   begin
   	select @msg='IN Location must be active.',@rcode=1
   	goto bspexit
   end
   
   
   
   
   
   
   ------------------------------------------------------- 
   bspexit:
--   	if @rcode=1 select @msg = @msg + ' [bspINMOLocationVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOLocationVal] TO [public]
GO
