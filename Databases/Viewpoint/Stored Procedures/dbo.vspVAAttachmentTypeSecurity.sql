SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vspVAAttachmentTypeSecurity]
/********************************************************
 * Created: JonathanP 04/25/08 - See issue #127475. Created for attachment type security. 
 *							     This method was adapated from vspRPReportSecurity.
 *			Jonathanp 05/20/08 - See issue #128382. Remove select @user = 'jonathanp'
 * Modified:  RickM 10/28/09 - Allow access to unsecured attachment types.
 *				jeremiahb 1/14/10	#128753	Added the VPUserName parameter.
 *
 * Used to determine attachment type security level for a specific 
 * attachment type and user.
 *
 * Inputs:
 *	@company			Company# to check.
 *	@attachmentTypeID	Attachment Type ID
 *	
 * Outputs:
 *	@accessLevel		Access level: 0 = full, 2 = denied, null = missing
 *	@errorMessage		Error message
 *
 * Return Code:
 *	@returnCode			0 = success, 1 = error
 *
 *********************************************************/

	(@company tinyint = null, @attachmentTypeID int = null, @user bVPUserName,
	 @access tinyint output, @errorMessage varchar(512) output)
as

set nocount on

declare @returnCode int
select @returnCode = 0		

-- Validate input parameters.
if @company is null or @attachmentTypeID is null 
	begin
	select @errorMessage = 'Missing required input parameter(s): Company # and/or Attachment Type ID#!', @returnCode = 1
	goto vspexit
	end

-- Set the access level to full access. This can change as we go through this procedure.
select @access = 0				

-- Get the user name.
--declare @user bVPUserName
--select @user = suser_sname()

-- Make sure the attachment type exists
if not exists(select top 1 1 from dbo.DMAttachmentTypesShared where AttachmentTypeID =  @attachmentTypeID)
	begin
	select @errorMessage = 'Invalid Attachment Type ID!', @returnCode = 1
	goto vspexit
	end

-- Viewpoint login has full access.
--if @user = 'viewpointcs' goto vspexit	
	
-- Get the attachment type name. This is used for error messages.
declare @attachmentTypeName varchar(50), @secured bYN	
select @attachmentTypeName=Name, @secured=Secured  from dbo.DMAttachmentTypesShared (nolock) where AttachmentTypeID = @attachmentTypeID
	
if @secured = 'N' goto vspexit --If the type is unsecured, then give them access.	
	
-- 1st check: Attachment Type security for user and active company, Security Group -1
select @access = Access
	from dbo.vVAAttachmentTypeSecurity (nolock)
	where Co = @company and AttachmentTypeID = @attachmentTypeID and SecurityGroup = -1 and VPUserName = @user	
	
	if @@rowcount = 1
		begin
		if @access = 0 goto vspexit		-- full access	
		if @access = 2	-- access denied
			begin
			select @errorMessage = @user + ' has been denied access to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')', @returnCode = 1
			goto vspexit
			end
			
		select @errorMessage = 'Invalid access value assigned to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')' + ' for ' + @user, @returnCode = 1
		goto vspexit
		end
	
-- 2nd check: Attachment Type security for user across all companies, Security Group -1 and Company = -1
select @access = Access
	from dbo.vVAAttachmentTypeSecurity (nolock)
	where Co = -1 and AttachmentTypeID = @attachmentTypeID and SecurityGroup = -1 and VPUserName = @user	

	if @@rowcount = 1
		begin
		if @access = 0 goto vspexit		-- full access
		if @access = 2	-- access denied
			begin
			select @errorMessage = @user + ' has been denied access to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')', @returnCode = 1
			goto vspexit
			end
			
		select @errorMessage = 'Invalid access value assigned to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')' + ' for ' + @user, @returnCode = 1
		goto vspexit
		end
		
-- 3rd check: Attachment type security for groups that user is a member of within active company
select @access = null

	select @access = min(Access)	-- get least restrictive access level
		from dbo.vVAAttachmentTypeSecurity t (nolock)
		join dbo.vDDSU s (nolock) on s.SecurityGroup = t.SecurityGroup 
		where t.Co = @company and t.AttachmentTypeID = @attachmentTypeID and s.VPUserName = @user

		-- Full access
		if @access = 0 goto vspexit		

		-- Access denied
		if @access = 2	
			begin
			select @errorMessage = @user + ' has been denied access to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')', @returnCode = 1
			goto vspexit
			end

		if @access is not null
			begin
			select @errorMessage = 'Invalid access value assigned to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')' + ' for ' + @user, @returnCode = 1
			goto vspexit
			end
	
-- 4th check: Attachment Type security for groups that user is a member of across all companies, Company = -1
select @access = min(Access)	-- get least restrictive access level
	from dbo.vVAAttachmentTypeSecurity t (nolock)
	join dbo.vDDSU s (nolock) on s.SecurityGroup = t.SecurityGroup 
	where t.Co = -1 and t.AttachmentTypeID = @attachmentTypeID and s.VPUserName = @user

	-- No entries for user in any security group
	if @access is null		
		begin
		select @errorMessage = @user + ' has not been setup with access to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')', @returnCode = 1
		goto vspexit
		end

	-- Full access
	if @access = 0 goto vspexit		

	-- Access denied
	if @access = 2	
		begin
		select @errorMessage = @user + ' has been denied access to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')', @returnCode = 1
		goto vspexit
		end
		
	select @errorMessage = 'Invalid access value assigned to Attachment Type ' + @attachmentTypeName + ' (ID = ' + convert(varchar,@attachmentTypeID) + ')' + ' for ' + @user, @returnCode = 1
	goto vspexit
	
vspexit:
	if @returnCode <> 0 select @errorMessage = @errorMessage + char(13) + char(10) + '[vspVAAttachmentTypeSecurity]'
	return @returnCode
GO
GRANT EXECUTE ON  [dbo].[vspVAAttachmentTypeSecurity] TO [public]
GO
