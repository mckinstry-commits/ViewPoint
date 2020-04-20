SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMGLAcctVal    Script Date: 8/28/99 9:34:16 AM ******/
   CREATE  proc [dbo].[bspCMGLAcctVal]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
    *
    * USAGE:
    * validates CM GL Account
    *	Must be Active
    *	AcctType cannot be Memo or Heading
    *	SubType must be 'C' or null
    * 
    * INPUT PARAMETERS
    *   CMCo        CM Co 
    *   GLacct      GL Account you want to validate
    * OUTPUT PARAMETERS
    *   @msg     Error message if invalid, otherwise GL Desctiption
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
    	(@cmco bCompany = 0, @glacct bGLAcct = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   	declare @glco bCompany, @active bYN, @accttype char(1), @subtype char(1), @rcode int
   	select @rcode = 0
   
   
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @glco = GLCo from bCMCO where CMCo = @cmco
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Company not on file!', @rcode = 1
   	goto bspexit
   	end
   
   select @active = Active, @accttype = AcctType, @subtype = SubType, @msg = Description 
   	from bGLAC
   	where GLCo = @glco and GLAcct = @glacct
   
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Account not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if @active <> 'Y' 
   	begin
   	select @msg = 'GL Account must be Active!', @rcode = 1
   	goto bspexit
   	end
   
   if @accttype = 'M' or @accttype = 'H'
   	begin
   	select @msg = 'GL Account cannot be a (Memo) or (Heading) Account Type!', @rcode = 1
   	goto bspexit
   	end
   
   if @subtype <> 'C' and @subtype is not null
   	begin
   	select @msg = 'GL Account Sub Ledger type must be Cash or null!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMGLAcctVal] TO [public]
GO
