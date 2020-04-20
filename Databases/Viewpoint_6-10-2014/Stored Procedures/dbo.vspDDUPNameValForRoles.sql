SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspDDUPNameVal    Script Date: 8/28/99 9:34:22 AM ******/
CREATE  proc [dbo].[vspDDUPNameValForRoles]
/**********************************************
* Created:		CHS	11/25/2009	- #135527
* Modified:
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
(@jcco bCompany, 
	@job bJob, 
	@username bVPUserName = null, 
	@role varchar(20) = null output, 
	@roleninenine varchar(20) = null output, 
	@multirow char(1) = null output,
	@rolesdesc varchar(60) = null output,
	@msg varchar(60) output)

as
set nocount on

declare @rcode int, @myrowcount int
select @rcode = 0

if @username is null
	begin
	select @msg = 'Missing user name', @rcode = 1
	goto vspexit
	end

select @msg = FullName
from dbo.DDUP with (nolock)
where VPUserName = @username
if @@rowcount = 0
	begin
	select @msg = 'User name not on file', @rcode = 1
	goto vspexit
	end
	
select @role = vJCJobRoles.Role, @roleninenine = vJCJobRoles.Role, @multirow = 'N', @rolesdesc = vHQRoles.Description
from dbo.vJCJobRoles with (nolock)
left join dbo.vHQRoles  with (nolock) on vJCJobRoles.Role = vHQRoles.Role
where JCCo = @jcco and Job = @job and VPUserName = @username
select @myrowcount = @@rowcount

if @myrowcount = 0
	begin
	select @msg = 'Role name not on file.', @rolesdesc = 'No Role associated with UserName ' + @username + ' for Job ' + @job + '.', @rcode = 1
	end	
if @myrowcount > 1
	begin
	select @multirow = 'Y'
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUPNameValForRoles] TO [public]
GO
