SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDUPGetEmailAddress]
/**********************************************
* Created: CC 01/17/08
* Modified: 
*
* Returns email address for a given username
*
* Inputs:
*	@uname		User name to get email address for
*	
* Outputs:
*	@msg		Email adress or error message
*
* Return code:
*	0 = success, 1 = failure
*
*************************************/

  	(@uname bVPUserName = null, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @uname is null
	begin
	select @msg = 'Missing user name', @rcode = 1
	goto vspexit
	end

select @msg = EMail
from dbo.DDUP (nolock)
where VPUserName = @uname
if @@rowcount = 0
	begin
	select @msg = 'User name not on file', @rcode = 1
	end
if @msg is null
	select @msg = 'No email address', @rcode = 1
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUPGetEmailAddress] TO [public]
GO
