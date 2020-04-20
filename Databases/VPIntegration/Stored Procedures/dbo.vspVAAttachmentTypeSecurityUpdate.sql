SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAAttachmentTypeSecurityUpdate]
-- =============================================
-- Created:	JonathanP 04/24/08 - This stored procedure was adapted from vspVARSUpdateSecurity.
--								 
-- Modified: AL 9/27/12 - Changed Security Group to Int
--
-- Description:	Inserts, updates, and deletes Attachment Type Security records
--
-- Inputs:
--	@company			Co# or -1 for all companies
--	@attachmentTypeID	AttachmentTypeID
--	@securityGroup		Security Group or -1 for User entries
--	@userName			User name or '' for Security Group entries
--	@access				0 = allowed, 1 = none (delete Security entry), 2 = denied (only valid with User entries)
--
-- ============================================= 
	(@company smallint = null, @attachmentTypeID integer = null,  @securityGroup INT = null,
	 @userName varchar(128) = null, @access TINYINT = null, @errorMessage varchar(255) output)

AS

SET NOCOUNT ON

DECLARE @returnCode int
SELECT @returnCode = 0

-- Validate company.
IF @company is null or @company < -1 or @company > 255
	BEGIN
	SELECT @errorMessage = 'Invalid Company #!', @returnCode = 1
	GOTO vspExit
	END
	
-- Validate attachment type ID		
IF @attachmentTypeID is null or @attachmentTypeID < 1 -- Attachment Type IDs have to be greater than 0
	BEGIN
	SELECT @errorMessage = 'Invalid Attachment Type ID!', @returnCode = 1
	GOTO vspExit
	END
	
-- Validate security group.
IF @securityGroup is null or @securityGroup < -1 
	BEGIN
	SELECT @errorMessage = 'Invalid Security Group#!', @returnCode = 1
	GOTO vspExit
	END
	
-- Validate user name.	
IF @userName is null
	BEGIN
	SELECT @errorMessage = 'Missing User Name!', @returnCode = 1
	GOTO vspExit
	END
	
-- Make sure the user name is blank if are updating a security group.
IF @securityGroup > -1 and @userName <> ''
	BEGIN
	SELECT @errorMessage = 'Security Group entries require a blank User Name!', @returnCode = 1
	GOTO vspExit
	END
	
-- Make sure if no group is specified, userName is not the empty string.
IF @securityGroup = -1 and @userName = ''
	BEGIN
	SELECT @errorMessage = 'User entries require a User Name!', @returnCode = 1
	GOTO vspExit
	END	
	
-- Make sure the access level is 0, 1, or 2.	
IF @access not in (0,1,2)
	BEGIN
	SELECT @errorMessage = 'Invalid Access level, must be 0-allowed, 1-none, or 2-denied!', @returnCode = 1
	GOTO vspExit
	END
	
-- If denying access, make sure we are not denying a security since that is not allowed.
IF @access = 2 and @securityGroup <> -1
	BEGIN
	SELECT @errorMessage = 'Invalid Access level, cannot deny access by Security Group!', @returnCode = 1
	GOTO vspExit
	END

-- If Access is 1 = none, delete existing vVAAttachmentTypeSecurity entry.
IF @access = 1
	BEGIN 
	DELETE dbo.vVAAttachmentTypeSecurity
		WHERE Co = @company and AttachmentTypeID = @attachmentTypeID and SecurityGroup = @securityGroup
			and VPUserName = @userName
	GOTO vspExit
	END
	
-- Make sure the attachment type ID is valid
IF NOT EXISTS(SELECT TOP 1 1 FROM DMAttachmentTypesShared WHERE AttachmentTypeID = @attachmentTypeID)
	BEGIN
	SELECT @errorMessage = 'Invalid attachment type ID. Could not update security.', @returnCode = 1
	GOTO vspExit
	END

-- Update/insert Report Security for Access levels 0 = allowed and 2 = denied
UPDATE dbo.vVAAttachmentTypeSecurity
	SET Access = @access
	WHERE Co = @company and AttachmentTypeID = @attachmentTypeID 
		and SecurityGroup = @securityGroup
		and VPUserName= @userName
	
-- If no rows were updated, then insert in a new attachment type security record.
IF @@ROWCOUNT = 0
	BEGIN
	INSERT dbo.vVAAttachmentTypeSecurity (Co, AttachmentTypeID, SecurityGroup, VPUserName, Access)
		VALUES(@company, @attachmentTypeID, @securityGroup, @userName, @access)
END

vspExit:    
    RETURN @returnCode 


GO
GRANT EXECUTE ON  [dbo].[vspVAAttachmentTypeSecurityUpdate] TO [public]
GO
