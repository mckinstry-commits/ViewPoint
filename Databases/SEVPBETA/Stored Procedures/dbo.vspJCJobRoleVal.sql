SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE PROCEDURE [dbo].[vspJCJobRoleVal]
/***********************************************************
* CREATED BY:	GF 10/15/2009 - issue #135527
* MODIFIED By:
*
* USAGE:
* validates JC Job Role and returns role description
*
* INPUT PARAMETERS
* JCCo   JCCo to validate
* Job    Job to validate
* Role	 Job Role to validate
*
* OUTPUT PARAMETERS                    
* @msg   error message if error occurs otherwise Description of role
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @job bJob = null, @role varchar(20) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @active char(1)

set @rcode = 0
set @active = 'N'

if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @job is null
	begin
	select @msg = 'Missing Job!', @rcode = 1
	goto bspexit
	end


---- validate role to HQ must be active
select @msg = r.Description, @active = r.Active
from dbo.HQRoles r with (nolock)
where r.Role = @role
if @@rowcount = 0
	begin
	select @msg = 'Role not on file in HQ.' , @rcode = 1
	goto bspexit
	end

if @active = 'N'
	begin
	select @msg = 'Invalid role, not active.', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode
	

GO
GRANT EXECUTE ON  [dbo].[vspJCJobRoleVal] TO [public]
GO
