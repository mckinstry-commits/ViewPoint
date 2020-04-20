SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMGLOffsetAcctValForFuelPosting]
/***********************************************************
* CREATED BY:	JM 4/3/02 (Adpted from  bspEMGLTransAcctValForFuelPosting)
* MODIFIED By: GF 02/11/2003 - issue #20328 using wrong GLCo for IN offset acct
*				TV 02/11/04 - 23061 added isnulls	
*				TRL 12/09/09 - Issue 134218 Added Isnulls and  changed GL Sub Type Validation
* USAGE:
* 	Validates a GL Account to make sure you can post to it.
* 	An error is returned if any of the following occurs
*   		GL Co# or GLAcct not found
*  		GLAcct Inactive, Heading Account, Memo Account
*		GLAcct Subtype other than 'I' or null if INLoc specified
*		GLAcct Subtype other than 'N' if no INLoc specified
*
* INPUT PARAMETERS
*	@emco		EM Co - if INCo null, determines GLCo
*   	@inco 	        	IN Co - if not null, determines GLCo
*   	@glacct	GL Account to validate
*   	@inloc		INLoc
*
* OUTPUT PARAMETERS
*   	@msg      	error message if error occurs
*
* RETURN VALUE

*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany = null, @inco bCompany = null, @glacct bGLAcct = null, 
@inloc bLoc = null, @msg varchar(255) output)
as
set nocount on

declare @glco bCompany, @rcode int, @accttype char(1), @active char(1), @subtype char(1)

select @rcode = 0

if @emco is null
begin
	select @msg = 'Missing EM Co#!', @rcode = 1
	goto bspexit
end

if isnull(@glacct,'')=''
begin
	select @msg = 'Missing GL Acct!', @rcode = 1
	goto bspexit
end

-- Select GLCo based on whether INCo passed in or not
if @inco is not null and isnull(@inloc,'')<>''
	begin 
		select @glco = GLCo from bINCO where INCo = @inco
	end 
else
	begin 
		select @glco = isnull(GLCo,@emco) from bEMCO where EMCo = @emco
	end

-- Validate @glacct
select @accttype = AcctType, @subtype = SubType, @active = Active, @msg=Description 
from dbo.GLAC with (nolock) where GLCo = @glco and GLAcct = @glacct

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

if @inco is not null and isnull(@inloc,'')<>'' 
	begin
		If @subtype <> 'I' and isnull(@subtype,'')<>''
		begin
			select @msg = 'GL Trans Acct must be SubType I or blank when INLoc specified!',@rcode = 1
			goto bspexit
		end
	end
else
	begin
		if   @subtype <> 'E' and isnull(@subtype,'')<>''
		begin
			select @msg = 'GL Trans Acct must be E or Null!',@rcode = 1
			goto bspexit
		end
	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMGLOffsetAcctValForFuelPosting]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMGLOffsetAcctValForFuelPosting] TO [public]
GO
