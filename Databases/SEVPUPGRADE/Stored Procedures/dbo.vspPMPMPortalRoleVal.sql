SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE  proc [dbo].[vspPMPMPortalRoleVal]
/*********************************************
 * Created By:	GF 05/30/2007
 * Modified By:
 *
 *
 * validates PM Firm Contact portal role
 *
 * Pass:
 * Role
 *
 * Returns:

 *
 * Success returns:
 * Role Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@role int, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @role is null
	begin
   	select @msg = 'Missing Portal Role!', @rcode = 1
   	goto bspexit
   	end

---- validate portal role
select @msg=Name from PortalRoles where RoleID=@role
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid role ' + isnull(convert(varchar(10),@role),'') + ' not on file!', @rcode = 1
	goto bspexit
	end


bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPMPortalRoleVal] TO [public]
GO
