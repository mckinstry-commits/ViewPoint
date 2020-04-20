SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAUpdateQuerySecurity]
-- =============================================
-- Created:	CC  09/10/08
-- Modified: AL 9/27/12
--
-- Description:	Inserts, updates, and deletes Query Security records
--
-- Inputs:
--	@company		Co# or -1 for all companies
--	@QueryName		Query Name
--	@securitygroup	Security Group or -1 for User entries
--	@username		User name or '' for Security Group entries
--	@access			0 = allowed, 1 = none (delete Security entry), 2 = denied (only valid wuth User entries)
--
-- ============================================= 
	(@company smallint = null, @QueryName VARCHAR(50) = null,  @securitygroup INT = null,
	 @username varchar(128) = null, @access TINYINT = null, @msg varchar(255) output)

as

SET NOCOUNT ON

declare @rcode int
select @rcode = 0

-- validate inputs variables
if @company is null or @company < -1 or @company > 255
	begin
	select @msg = 'Invalid Company #!', @rcode = 1
	goto vspexit
	end
if @QueryName is null
	begin
	select @msg = 'Invalid Query Name!', @rcode = 1
	goto vspexit
	end
if @securitygroup is null or @securitygroup < -1 
	begin
	select @msg = 'Invalid Security Group#!', @rcode = 1
	goto vspexit
	end
if @username is null
	begin
	select @msg = 'Missing User Name!', @rcode = 1
	goto vspexit
	end
if @securitygroup > -1 and @username <> ''
	begin
	select @msg = 'Security Group entries require a blank User Name!', @rcode = 1
	goto vspexit
	end
if @securitygroup = -1 and @username = ''
	begin
	select @msg = 'User entries require a User Name!', @rcode = 1
	goto vspexit
	end
if @access not in (0,1,2)
	begin
	select @msg = 'Invalid Access level, must be 0-allowed, 1-none, or 2-denied!', @rcode = 1
	goto vspexit
	end
if @access = 2 and @securitygroup <> -1
	begin
	select @msg = 'Invalid Access level, cannot deny access by Security Group!', @rcode = 1
	goto vspexit
	end

-- if Access is 1 = none, delete existing vRPRS entry
IF @access = 1
	BEGIN 
		DELETE dbo.VPQuerySecurity
		WHERE Co = @company and QueryName = @QueryName and SecurityGroup = @securitygroup
			and VPUserName = @username
		GOTO vspexit
	END

-- update/insert Report Security for Access levels 0=allowed and 2=denied
UPDATE dbo.VPQuerySecurity
SET Access = @access
WHERE Co = @company and QueryName = @QueryName and SecurityGroup = @securitygroup
	 and VPUserName= @username
if @@rowcount = 0
	begin
		INSERT dbo.VPQuerySecurity (Co, QueryName, SecurityGroup, VPUserName, Access)
		VALUES(@company, @QueryName, @securitygroup, @username, @access)
	end

vspexit:    
    return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateQuerySecurity] TO [public]
GO
