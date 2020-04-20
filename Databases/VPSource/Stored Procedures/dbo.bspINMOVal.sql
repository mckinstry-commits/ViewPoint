SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspINMOVal]
   /*******************************************
   Created: RM 04/04/02
   
   
   Usage: Used to validate that a MO# is not already in use.
   
   In:
   	@inco - IN Company
       @mo   - Material Order
   Out:
   	@msg   - error message
       @rcode - return code, 1 if error, 0 if OK.
   *******************************************/
   (@inco bCompany = null, @mo varchar(10) = null,@moout varchar(10) = null output, @msg varchar(255) = null output)
   as
   
   
   declare @rcode int
   select @rcode = 0
   
   if @inco is null
   begin
   	select @msg = 'Missing IN Company.',@rcode = 1
   	goto bspexit
   end
   
   if @mo is null
   begin
   	select @msg = 'Missing Material Order.',@rcode = 1
   	goto bspexit
   end
   
   
   if exists(select 1 from bINMO where INCo=@inco and MO=@mo) or 
   	exists(select 1 from bINMB where Co=@inco and MO=@mo)
   begin
   	select @msg = 'Invalid MO, already in use',@rcode = 1
   	goto bspexit
   end
   
   
   
   if @mo = '+' or upper(@mo) = 'NEW'
   begin
   	exec @rcode = bspINMONextMO @inco,@moout output
   	if @rcode <> 0
   	begin
   		
   		select @moout = @mo,@msg = 'Error getting next MO.'
   		goto bspexit
   	end
   end
   else
   begin
   	select @moout = @mo
   end
   
   bspexit:
   --	if @rcode =1 select @msg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOVal] TO [public]
GO
