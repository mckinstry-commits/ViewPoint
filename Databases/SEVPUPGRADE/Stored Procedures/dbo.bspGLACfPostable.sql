SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspGLACfPostable]
    /***********************************************************
     * CREATED BY: SE   10/09/96
     * MODIFIED By : GG 07/19/98
     *					EN 11/10/04 issue 26035 do not disregard Memo Accounts if @chksubtype = 'M'
	 *					GF 01/04/2008 - issue #126528 added @glco to error messages for clarity.
	 *					EN 01/06/2009 - #120326 removed need for @chksubtype = 'M' validation ... bspPRUpdateValGLExp no longer calls this procedure
	 *					GP 03/02/2010 - issue #138280 removed check for @accttype = 'M', memo
*
     *
     * USAGE:
     * Validates a GL Account to make sure you can post to it.
     * An error is returned if any of the following occurs
     *     GL Co# or GLAcct not found
     *     GLAcct Inactive
     *     GLAcct Heading Account or Memo Account
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
	select @msg = 'Missing GL Co!', @rcode = 1
	goto bspexit
	end

if @glco is null
	begin
	select @msg = 'Missing GL Co!', @rcode = 1
	goto bspexit
	end

if @glacct is null or @glacct=space(len(@glacct))
	begin
	select @msg = 'Missing GL Account!', @rcode = 1
	goto bspexit
	end
    
    select @accttype = AcctType, @subtype = SubType, @active = Active, @msg=Description
    from bGLAC with (nolock) 
    where GLCo = @glco and GLAcct = @glacct
    if @@rowcount = 0
   	begin
    	select @msg = 'GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @glacct + ' not found!', @rcode = 1
		goto bspexit
      	end
    if @accttype = 'H'
   	begin
       select @msg = 'GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @glacct + ' is a Heading Account!', @rcode=1
       goto bspexit
   	end
   	--138280 removed check for @accttype = 'M', memo
    if @active = 'N'
   	begin
       select @msg = 'GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @glacct + ' is inactive!', @rcode = 1
   	goto bspexit
      	end
    if @chksubtype = 'N' and @subtype is not null
   	begin
    	select @msg = 'GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @glacct + ' is Subledger Type: ' + @subtype + '.  Must be null!', @rcode = 1
   	goto bspexit
   	end
    
    if @chksubtype is not null and @subtype is not null
    	begin
    	if @subtype <> @chksubtype
            begin
          	select @msg = 'GL Co: ' + isnull(convert(varchar(3),@glco),'') + ' GL Account: ' + @glacct + ' is Subledger Type: ' + @subtype + '.  Must be ' + @chksubtype + ' or null!'
    		select @rcode = 1
          	goto bspexit
        	end
    	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLACfPostable] TO [public]
GO
