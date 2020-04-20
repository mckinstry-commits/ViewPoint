SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGLTransAcctValForFuelPosting    Script Date: 4/4/2002 9:45:05 AM ******/
   CREATE  proc [dbo].[bspEMGLTransAcctValForFuelPosting]
   /***********************************************************
   * CREATED BY: JM 4/3/02 (Adapted from  bspEMGLTransAcctVal)
   * MODIFIED By : TV 02/11/04 - 23061 added isnulls	
   *
   * USAGE:
   * 	Validates a GL Account to make sure you can post to it.
   * 	An error is returned if any of the following occurs
   *   		GL Co# or GLAcct not found
   *  		GLAcct Inactive, Heading Account, Memo Account
   *		GLAcct Subtype other than 'E' or null
   *
   * INPUT PARAMETERS
   *	@emco		Determines GLCo
   *   	@glacct	GL Account to validate
   *
   * OUTPUT PARAMETERS
   *   	@msg      	error message if error occurs
   *
   * RETURN VALUE
   
   *   0         success
   *   1         Failure
   *****************************************************/
   (@emco bCompany = null, @glacct bGLAcct = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @glco bCompany, @rcode int, @accttype char(1), @active char(1), @subtype char(1)
   
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Co#!', @rcode = 1
   	goto bspexit
   	end
   
   if @glacct is null
   	begin
   	select @msg = 'Missing GL Account!', @rcode = 1
   	goto bspexit
   	end
   	
   -- Select GLCo based on EMCo 
   select @glco = GLCo from bEMCO with (nolock) where EMCo = @emco
   
   -- Validate @glacct
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
   
   if @subtype <> 'E' and @subtype is not null
   	begin
   	select @msg = 'GL Trans Acct must be SubType E or blank!'
   	goto bspexit
   	end
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMGLTransAcctValForFuelPosting]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMGLTransAcctValForFuelPosting] TO [public]
GO
