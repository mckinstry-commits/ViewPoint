SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLAcctValWithNormBal    Script Date: 8/28/99 9:34:40 AM ******/
   CREATE  proc [dbo].[bspGLAcctValWithNormBal]
   	(@glco bCompany = 0, @glacct bGLAcct = null, @normbal char(1) = null output,  @msg varchar(60) output)
   as
   /***********************************************************
    * CREATED BY: SE   12/12/96
    * MODIFIED By : SE 12/12/96
    *				 MV 01/31/03 - #20246 dbl quote cleanup.
    * USAGE:
    * Validates GL Acct and returns the normal balance
    * an error is returned if the acct is invalid
    *
    * INPUT PARAMETERS
    *   GLCo	GL CO
    *   GLAcct 	GLAccount
    *
    * OUTPUT PARAMETERS
    *   NormBal	Default Balance
    *   @msg       error message if error occurs otherwise Description of Contract Item
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
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
   
   select @msg = Description, @normbal=NormBal from bGLAC
   	where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Account not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLAcctValWithNormBal] TO [public]
GO
