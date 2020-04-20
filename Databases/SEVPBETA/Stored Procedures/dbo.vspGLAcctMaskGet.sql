SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspGLAcctMaskGet]
/************************************
* Created: 	GG 11/03/05
* Modified:	GG 02/29/08 - #127031 - fix for bFRXAcct
*
* Usage:
*	Called by the GLAP form (GL Accounts Parts) to
*	return the the GL Account mask.
*
* Inputs:
*	@co			GL Co# to validate (even though GLAcct mask is same for all companies)
*
* Outputs:
*	@glmask		Input mask for bGLAcct datatype
*	@errmsg		message if procedure fails
*
* Return code:
*	0 = success, 1 = error
*
**********************************************/

  	(@co bCompany = null, @glmask varchar(20)output, @errmsg varchar(255) output)

as
  
set nocount on
  
declare @rcode int
  
select @rcode = 0

if not exists(select top 1 1 from dbo.GLCO (nolock) where GLCo = @co)
	begin
	select @errmsg = 'GL Co# ' + convert(varchar,@co) + ' is not setup!', @rcode = 1
	goto vspexit
	end
	
-- get mask for GL Account datatype 
-- if bFRXAcct type exists with a non-null mask use it for account parts
select @glmask = InputMask
from dbo.DDDTShared (nolock) where Datatype = 'bFRXAcct'  -- #127031
if @@rowcount = 0 or @glmask is null
	begin
	select @glmask = InputMask 
	from dbo.DDDTShared with (nolock) where Datatype = 'bGLAcct' 
	if @@rowcount = 0
  		begin
  		select @errmsg = 'Missing datatype ''bGLAcct'' in DD Datatypes!', @rcode = 1
  		goto vspexit
  		end
	end
  
vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLAcctMaskGet] TO [public]
GO
