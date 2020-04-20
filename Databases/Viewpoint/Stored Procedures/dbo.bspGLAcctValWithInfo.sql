SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLAcctValWithInfo    Script Date: 8/28/99 9:34:39 AM ******/
   CREATE   proc [dbo].[bspGLAcctValWithInfo]
   /***********************************************************
    * CREATED BY: JM   5/3/98
    * MODIFIED By : GG 08/06/01 - #14063 - allow Memo Accounts
    *				 MV 01/31/03 - #20246 dbl quote cleanup.
    * USAGE:
    *	Used for validation of GL Accounts when inactive or memo accounts
    *	can be entered (e.g. Budgets, Prior Activity)
    *
    * INPUT PARAMETERS
    *   @glco			GL Company
    *   @glacct		GL Account
    *
    * OUTPUT PARAMETERS
    *   @normbal		Normal balance, 'D' = debit, 'C' = credit
    *   @accttype		Account Type
    *   @msg       	Account description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   	(@glco bCompany = 0, @glacct bGLAcct = null, @normbal char(1) = null output,
   	 @accttype char(1) = null output, @msg varchar(60) output)
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
   
   select @msg = Description, @normbal = NormBal, @accttype = AcctType 
   from bGLAC
   where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Account not on file!', @rcode = 1
   	goto bspexit
   	end
   if @accttype = 'H' 
   	begin
   	select @msg = 'This GL Account is a Heading Account', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLAcctValWithInfo] TO [public]
GO
