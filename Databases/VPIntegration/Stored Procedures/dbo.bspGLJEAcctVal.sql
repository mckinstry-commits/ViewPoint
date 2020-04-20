SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspGLJEAcctVal]
   /***********************************************************
    * Created: GG 04/10/01
    * Modified:
    *
    * USAGE:
    * Called by GL Journal Entry to validate GL Account.
    *
    * INPUT
    *   @glco	     GL Company
    *   @glacct	 GL Account to validate
    *
    * OUTPUT
    *   @msg        Account description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@glco bCompany = null, @glacct bGLAcct = null, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @accttype char(1), @active char(1)
   
   select @rcode = 0
   
   if @glco is null
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @accttype = AcctType, @active = Active
   from bGLAC where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
       begin
       select @msg = 'Invalid GL Account.', @rcode = 1
       goto bspexit
       end
   if @accttype = 'H'
       begin
       select @msg = 'Heading account.', @rcode=1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Account is inactive.', @rcode=1
       goto bspexit
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLJEAcctVal] TO [public]
GO
