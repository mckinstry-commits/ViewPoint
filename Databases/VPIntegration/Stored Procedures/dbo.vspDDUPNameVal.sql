SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDUPNameVal    Script Date: 8/28/99 9:34:22 AM ******/
CREATE  proc [dbo].[vspDDUPNameVal]
/**********************************************
* Created: ??
* Modified: GG 08/03/07 - return FullName 
*
* Validates VPUserName
*
* Inputs:
*	@uname		User name to validate
*	
* Outputs:
*	@msg		Show PR rates flag or error message
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

select @msg = FullName
from dbo.DDUP (nolock)
where VPUserName = @uname
if @@rowcount = 0
	begin
	select @msg = 'User name not on file', @rcode = 1
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUPNameVal] TO [public]
GO
