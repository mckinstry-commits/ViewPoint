SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************/
CREATE proc [dbo].[vspHQRoleJobCheck]
/*************************************
 * Created By:	GF 10/15/2009 - issue #135527
 * Modified By:
 *
 *
 * verifies that the HQ Role is not in use in JCJM for delete.
 *
 *
 * Pass:
 * role				HQ Role
 *
 * Success returns:
 * 0
 *
 * Error returns:
 * 1 and error message
  **************************************/
(@role varchar(20), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if @role is null goto bspexit

---- check JCJobRoles to see if role is in use
if exists(select top 1 1 from dbo.JCJobRoles with (nolock) where Role = @role)
	begin
	select @msg = 'Role is currently in use in JC Job Master.', @rcode = 1
	goto bspexit
	end
	
bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRoleJobCheck] TO [public]
GO
