SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLACAcctVal    Script Date: 8/28/99 9:34:38 AM ******/
   /*
    * DROP PROC dbo.bspGLAcctVal
    */
   CREATE   proc [dbo].[bspGLACAcctVal]
   /*	MODIFIED MV 01/31/03 - #20246 dbl quote cleanup.
    * validates GL Account
    * pass in GL Co# and Summary Account and GLAC Account
    * returns GL Account description
    * Special Validation in GLAC input where if the Account were checking is the
    * same as the record we're inserting then the account is valid.
    * so pass the account to validate and the account we're adding
   */
   	(@glco bCompany = 0, @sumacct bGLAcct = null, @glacct bGLAcct = null, @msg varchar(60) output)
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
   
   if @sumacct is null
   	begin
   	select @msg = 'Missing Summary Account!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Description from bGLAC
   	where GLCo = @glco and GLAcct = @sumacct
   
   if @@rowcount = 0
   	begin
           /* if both accounts are the same it's valid and return no Description*/
   	if @sumacct = @glacct 
              select @msg = '', @rcode = 0
           else
      	   select @msg = 'GL Account not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACAcctVal] TO [public]
GO
