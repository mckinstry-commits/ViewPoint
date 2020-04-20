SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLClosedMonthVal    Script Date: 8/28/99 9:35:45 AM ******/
   CREATE  proc [dbo].[bspSLClosedMonthVal]
   /******************************************
    * Created: ??
    * Modified: GG 07/15/99
    *
    * Validate that month is closed in Subledgers or Purchase Orders
    *
    * Pass;
    *	@slco        SL Company
    *	@month       Month
   
    *
    * Output:
    *  @msg         Error message
    *
    * Returns:
    *	0            success
    *  1            failure
   *******************************************/
   (@slco bCompany, @month bMonth, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int, @glco bCompany, @clsdmth bMonth
   
   select @rcode = 0
   
   /* get GL Company */
   select @glco = GLCo from bAPCO where APCo = @slco
   if @@rowcount = 0
   	begin
   	select @msg = 'AP Company is missing!', @rcode = 1
   	goto bspexit
   	end
   
   /* validate month closed */
   select @clsdmth = LastMthSubClsd
   from bGLCO
   where GLCo = @glco
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
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLClosedMonthVal] TO [public]
GO
