SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSClosedMonthVal]
   /******************************************
    * Created By:  GF 01/13/2001
    * Modified By:
    *
    * Validate that month is closed in Material Sales
    *
    * Pass;
    *	@msco        MS Company
    *	@month       Month
    *
    * Output:
    *  @msg         Error message
    *
    * Returns:
    *	0            success
    *  1            failure
   *******************************************/
   (@msco bCompany = null, @month bMonth = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @glco bCompany, @clsdmth bMonth
   
   select @rcode = 0
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end
   
   if @month is null
       begin
       select @msg = 'Missing MS Purge through month', @rcode = 1
       goto bspexit
       end
   
   -- get GL Company
   select @glco=GLCo from bMSCO where MSCo=@msco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid MS Company', @rcode = 1
   	goto bspexit
   	end
   
   -- validate month closed
   select @clsdmth = LastMthSubClsd
   from bGLCO where GLCo=@glco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid GL Company!', @rcode = 1
       goto bspexit
       end
   
   if @month > @clsdmth
   	begin
   	select @msg = 'Month must be closed!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSClosedMonthVal] TO [public]
GO
