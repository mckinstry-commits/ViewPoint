SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLClosedMthVal    Script Date: 8/28/99 9:34:42 AM ******/
   CREATE procedure [dbo].[bspGLClosedMthVal]
    /******************************************************
    * Created by: EN 9/18/98
    * Modified by: GG 07/15/99
    *
    * Validates that a month has been closed in GL
    *
    * pass in GL Co#, and Month to validate
    * returns 0 if successful (month has been closed), 1 if not
    *******************************************************/
    @glco bCompany, @mth bMonth
   
    as
    set nocount on
   
    declare @rcode int, @clsdmth bMonth
   
    select @rcode = 0
   
    /* check to see if month is open */
    select @clsdmth = LastMthGLClsd
    from bGLCO where GLCo = @glco
    if @@rowcount = 0
       begin
       select @rcode = 1
       goto bspexit
       end
   
    if @clsdmth is null or @mth > @clsdmth
     	begin
    	select @rcode = 1
    	goto bspexit
    	end
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLClosedMthVal] TO [public]
GO
