SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAUpdateTemplateSecurity]
-- =============================================
-- Created:	CC  09/10/08
-- Modified: AL Changed Security Group to INT
--
-- Description:	Inserts, updates, and deletes Template Security records
--
-- Inputs:
--	@company		Co# or -1 for all companies
--	@TemplateID		Template KeyID
--	@securitygroup	Security Group or -1 for User entries
--	@username		User name or '' for Security Group entries
--	@access			0 = allowed, 1 = none (delete Security entry), 2 = denied (only valid wuth User entries)
--
-- ============================================= 
	(@company smallint = null, @TemplateName VARCHAR(50) = null,  @securitygroup INT = null,
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
if @TemplateName is null
	begin
	select @msg = 'Invalid Template Name!', @rcode = 1
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
	DELETE dbo.VPCanvasTemplateSecurity
	WHERE Co = @company and TemplateName = @TemplateName and SecurityGroup = @securitygroup
		and VPUserName = @username
	GOTO vspexit
	END

-- update/insert Report Security for Access levels 0=allowed and 2=denied
UPDATE dbo.VPCanvasTemplateSecurity
SET Access = @access
WHERE Co = @company and TemplateName = @TemplateName and SecurityGroup = @securitygroup
	 and VPUserName= @username
if @@rowcount = 0
	begin
	INSERT dbo.VPCanvasTemplateSecurity (Co, TemplateName, SecurityGroup, VPUserName, Access)
	VALUES(@company, @TemplateName, @securitygroup, @username, @access)
	end

vspexit:    
    return @rcode 



GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateTemplateSecurity] TO [public]
GO
