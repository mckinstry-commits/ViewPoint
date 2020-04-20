SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspHQRoleUserValidation]
/***********************************************************
* CREATED BY:	NH	03/21/2012
* MODIFIED BY:
*				
* USAGE:
* Used in multiple forms to validate that the VP user is
* valid and is assigned to the role in HQ Role Users.
*
* INPUT PARAMETERS
*   Role   
*   VPUserName
*
* OUTPUT PARAMETERS
*   @msg		Description of Department if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 

(@Role varchar(20), @VPUserName bVPUserName, @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @Role is null
begin
	select @msg = 'Missing Role.', @rcode = 1
	goto vspexit
end

if @VPUserName is null
begin
	select @msg = 'Missing User Name.', @rcode = 1
	goto vspexit
end


--Check if given user is a valid VP user
exec @rcode = dbo.vspDDUPNameVal @VPUserName, @msg output
if @rcode = 1
begin
	goto vspexit
end


--Check if valid VP user has also been assigned a role
if not exists(select 1
			  from dbo.vHQRoleMember
			  where [Role] = @Role
			  and UserName = @VPUserName
			  and Active = 'Y')
begin
	select @rcode = 1, @msg = 'User has not been assigned an HQ Role or is inactive.'
	goto vspexit
end
	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRoleUserValidation] TO [public]
GO
