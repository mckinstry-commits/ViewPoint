SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************/
CREATE proc [dbo].[vspHQRoleDesc]
/***********************************************************
* CREATED BY:	GF 10/22/2009
* MODIFIED BY:	
*				
* USAGE:
* Used in HQ Roles to return the a description to the key field.
*
* INPUT PARAMETERS 
* Role
*
* OUTPUT PARAMETERS
* @msg      Description of role if found.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@role varchar(20) = null, @assigned char(1) = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

SET @rcode = 0
SET @msg = ''
set @assigned = 'N'

if @role is not null
	begin
	---- verify role is not a user in DDUP
	if exists(select 1 from dbo.DDUP with (nolock) where VPUserName = @role)
		begin
		select @msg = 'Invalid role. The role cannot also be a Viewpoint user.', @rcode = 1
		goto bspexit
		end
		
	---- Get Description
	select @msg = Description 
	from dbo.HQRoles with (nolock) where Role = @role
	
	---- check if role used on any job
	if exists(select 1 from dbo.vJCJobRoles with (nolock) where Role = @role)
		begin
		set @assigned = 'Y'
		end
		
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRoleDesc] TO [public]
GO
