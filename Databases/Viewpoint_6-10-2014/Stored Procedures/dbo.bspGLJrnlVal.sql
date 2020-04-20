SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLJrnlVal    Script Date: 8/28/99 9:34:44 AM ******/
   CREATE  proc [dbo].[bspGLJrnlVal]
   /*******************************************************
    * Created By:
    * Modified By: MV 04/12/06 - APCompany 6X Recode - change err msg
    *
    * validates GL Journal
    * pass in GL Co# and Journal
    * returns Journal description
   ********************************************************/
   (@glco bCompany = 0, @jrnl bJrnl = null, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @glco = 0 or @glco is null
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @jrnl is null
   	begin
   	select @msg = 'Missing Journal!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bGLJR
   where GLCo = @glco and Jrnl = @jrnl
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Journal ' + @jrnl + ' not on file for GL Company # ' + convert(varchar(5),@glco) + ' .', @rcode = 1
   	end 
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJrnlVal] TO [public]
GO
