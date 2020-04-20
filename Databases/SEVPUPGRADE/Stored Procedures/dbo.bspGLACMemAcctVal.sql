SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLACMemAcctVal    Script Date: 05/07/01 02:00:00 PM ******/
   CREATE   PROCEDURE [dbo].[bspGLACMemAcctVal]
   /***********************************************************
    * CREATED BY: AllenN 05/07/01
    * MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * USAGE:
    * Validates a Cross Reference GL Memo Account for the GL Chart of Accounts form
    * An error is returned if any of the following occurs
    *     GL Co# and GLAcct not found
    *     AcctType='H'
    *     AcctType<>'M' for the input parameter @memoacct
    *
    * INPUT PARAMETERS
    *   @glco 	        GLCo to validate against
    *   @glacct	    GL Account to validate against
    *   @memoacct      GL Memo Account to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    *
    * RETURN VALUE
    *  @rcode = 
    *   0         Success
    *   1         Failure
    *****************************************************/
   /* validates GL Memo Account
    * pass in GLCo, Memo Account, and GLAC Account 
    * returns GL Memo Account description
    *If the Memo AcctType ='M' and it exhists in bGLAC for the GLCo then it is ok.
    *If, however, the GLAC Account meets the condition AcctType='H' then all acocunts are invalid.
   */
   	(@glco bCompany = 0, @memoacct bGLAcct = null, @glacct bGLAcct = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   declare @valcount int
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
   
   if @memoacct is null
   	begin
   	select @msg = 'Missing Memo Account!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @valcount = count (*) from bGLAC where AcctType='H' and GLAcct = @glacct and GLCo=@glco
   if @valcount > 0
   	begin
   	select @msg = 'Memo accounts are invalid when used for a Header GL account.', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from bGLAC
   	where GLCo = @glco and GLAcct = @memoacct and AcctType='M'
   if @@rowcount = 0
   	begin
      	select @msg = 'Invalid, Memo Account Only!', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACMemAcctVal] TO [public]
GO
