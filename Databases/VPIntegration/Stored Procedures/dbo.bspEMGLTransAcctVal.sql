SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspEMGLTransAcctVal]
    /***********************************************************
     * CREATED BY: JM 1/19/99 (Copied from bspGLACfPostable)
     * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
     *
     * USAGE:
     * Validates a GL Account to make sure you can post to it.
     * An error is returned if any of the following occurs
     *   	GL Co# or GLAcct not found
     *  	GLAcct Inactive
     * 	GLAcct Heading Account or Memo Account
     *	GLAcct Subtype other than 'E' or null
     *
     * INPUT PARAMETERS
     *   @glco 	        GL Co to validate agains
     *   @glacct	    GL Account to validate
     *   @chksubtype	SubLedger Type - if null, can be any / if 'N', must be null / other, must be null or match
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     *
     * RETURN VALUE
    
     *   0         success
     *   1         Failure
     *****************************************************/
   (@glco bCompany = 0, @glacct bGLAcct = null, @chksubtype char(1) = null, @msg varchar(255) output)
   as
   set nocount on
    
   declare @rcode int, @accttype char(1), @active char(1), @subtype char(1)
    
   select @rcode = 0
    
   if @glco = 0
    	begin
    	select @msg = 'Missing GL Co#!', @rcode = 1
    	goto bspexit
    	end
   
   if @glacct is null
    	begin
    	select @msg = 'Missing GL Account!', @rcode = 1
    	goto bspexit
    	end
    
   select @accttype = AcctType, @subtype = SubType, @active = Active, @msg=Description
   from bGLAC with (nolock)
   where GLCo = @glco and GLAcct = @glacct
   if @@rowcount = 0
   	begin
    	select @msg = 'GL Account: ' + isnull(@glacct,'') + ' not found!', @rcode = 1
       goto bspexit
      	end
   
   if @accttype = 'H'
       begin
    	select @msg = 'GL Account: ' + isnull(@glacct,'') + ' is a Heading Account!', @rcode=1
    	goto bspexit
       end
   
   if @accttype = 'M'
    	begin
    	select @msg = 'GL Account: ' + isnull(@glacct,'') + ' is a Memo Account!', @rcode=1
    	goto bspexit
      	end
   
   if @active = 'N'
    	begin
    	select @msg = 'GL Account: ' + isnull(@glacct,'') + ' is inactive!', @rcode = 1
       goto bspexit
      	end
   
   if @chksubtype = 'N' and @subtype is not null
    	begin
     	select @msg = 'GL Account: ' + isnull(@glacct,'') + ' is Subledger Type: ' + isnull(@subtype,'') + '.  Must be null!', @rcode = 1
    	goto bspexit
       end
   
   if @chksubtype is not null and @subtype is not null
    	begin
    	if @subtype <> @chksubtype
   		begin
   		select @msg = 'GL Account: ' + isnull(@glacct,'') + ' is Subledger Type: ' + isnull(@subtype,'') + '.  Must be ' + isnull(@chksubtype,'') + '!', @rcode = 1
   		goto bspexit
     	   	end
    	end
   
   if @subtype <> 'E' and @subtype is not null
    	begin
    	select @msg = 'GL Trans Acct must be SubType E or blank!'
    	goto bspexit
    	end
    
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMGLTransAcctVal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMGLTransAcctVal] TO [public]
GO
