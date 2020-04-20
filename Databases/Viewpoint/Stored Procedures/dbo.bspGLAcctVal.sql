SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLAcctVal    Script Date: 8/28/99 9:34:39 AM ******/
   CREATE  proc [dbo].[bspGLAcctVal]
   /* validates GL Account
    * pass in GL Co# and GL Account
    * returns GL Account description
    *	MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
   */
   	(@glco bCompany = 0, @glacct bGLAcct = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bGLAC
   	where GLCo = @glco and GLAcct = @glacct
   
   
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Account not on file!', @rcode = 1 
   	end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLAcctVal] TO [public]
GO
