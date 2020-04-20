SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspGLACQtyVal]
   /***********************************************************
    * CREATED BY: GR 02/18/00
    *
    *
    * USAGE:
    * Validates a Quantity GL Account to make sure you can post to it.
    * this routine is invoked to validate qunatity GLAccounts  in
    * INLocationMaster, INLocCoOverride, INLocCoCatOverride, INLocCatOverride
    * An error is returned if any of the following occurs
    *     GL Co# or GLAcct not found
    *     GLAcct Inactive
    *
    *
    * INPUT PARAMETERS
    *   @glco 	        GL Co to validate against
    *   @glacct	    GL Account to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@glco bCompany = 0, @glacct bGLAcct = null, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @accttype char(1), @active char(1), @subtype char(1)
   
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Co!', @rcode = 1
   	goto bspexit
   	end
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @accttype = AcctType, @subtype = SubType, @active = Active, @msg=Description
   from bGLAC
   where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
      	begin
   	select @msg = 'GL Account: ' + @glacct + ' not found!', @rcode = 1
      	goto bspexit
     	end
   if @accttype <> 'M'
      	begin
       select @msg = 'GL Account: ' + @glacct + ' must be a Memo Account!', @rcode=1
       goto bspexit
      	end
   if @active = 'N'
      	begin
       select @msg = 'GL Account: ' + @glacct + ' is inactive!', @rcode = 1
      	goto bspexit
     	end
   if @subtype <> 'I' and @subtype is not null
      	begin
       select @msg = 'GL Account: ' + @glacct + ' is Subledger Type: ' + @subtype + '.  Must be null or I!', @rcode = 1
       goto bspexit
      	end
   
   bspexit:
       if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspGLACQtyVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACQtyVal] TO [public]
GO
