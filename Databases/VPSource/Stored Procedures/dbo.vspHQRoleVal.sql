SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE PROCEDURE [dbo].[vspHQRoleVal]
/***********************************************************
* CREATED BY:	JG	02/24/2012 - TK-12822
* MODIFIED By:	JG	03/05/2012 - TK-12822 - Flag to ignore whether active or not.
*
* USAGE:
* validates HQ Role and returns role description
*
* INPUT PARAMETERS
* Role			Job Role to validate
* IgnoreActive	Flag to ignore Active flag
*
* OUTPUT PARAMETERS                    
* @msg   error message if error occurs otherwise Description of role
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@role varchar(20) = null, @ignoreActive dbo.bYN = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @active char(1)

set @rcode = 0
set @active = 'N'

---- validate role to HQ must be active
select @msg = r.Description, @active = r.Active
from dbo.HQRoles r with (nolock)
where r.Role = @role
if @@rowcount = 0
	begin
	select @msg = 'Role not on file in HQ.' , @rcode = 1
	goto bspexit
	end

if @ignoreActive = 'N' AND @active = 'N'
	begin
	select @msg = 'Invalid role, not active.', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHQRoleVal] TO [public]
GO
