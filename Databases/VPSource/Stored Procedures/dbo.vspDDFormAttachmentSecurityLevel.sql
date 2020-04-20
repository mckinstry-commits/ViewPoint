SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDFormAttachmentSecurityLevel]
/********************************************************
* Created: JonathanP 05/18/09
*
* Description: #132390 Determines the attachment security level based on form security. This procedure was 
*			   adapated from vspDDFormSecurity. 
*
* Inputs:
*	@co		Active Company#
*	@form	Form name
*	
* Outputs:
*   @attachmentSecurityLevel	0 = Add, 1 = Add/Edit, 2 = Add/Edit/Delete, -1 = None
*	@errmsg		The return message
*
* Return Code:
*	@rcode		0 = success, 1 = error
*
*********************************************************/

	(@co bCompany = null, @form varchar(30) = null, @attachmentSecurityLevel int = null OUTPUT, @errmsg varchar(512) output)
as

set nocount on

declare @rcode int, @user bVPUserName, @mod char(2), @modliclevel tinyint, @formliclevel tinyint,
	@secureform varchar(30), @detailsecurity bYN

select @rcode = 0

if @co is null or @form is null 
	begin
	select @errmsg = 'Missing required input parameter(s): Company # and/or Form!', @rcode = 1
	goto vspexit
	end

-- get security form (security form should equal current form for all custom forms)
select @secureform = SecurityForm, @detailsecurity = DetailFormSecurity
from dbo.DDFHShared (nolock)
where Form = @form
if @@rowcount = 0
	begin
	select @errmsg = @form + ' is not setup in DD Form Header!', @rcode = 1
	goto vspexit
	end
	
-- check for security override. If it is set, use current not security form
if @detailsecurity = 'Y' set @secureform = @form
--validate security form
if @secureform <> @form 
	begin
	if not exists(select 1 from dbo.DDFHShared (nolock) where Form = @secureform)
		begin
		select @errmsg = 'Security form ' + @secureform + ' is not setup in DD Form Header!', @rcode = 1
		goto vspexit
		end
	end

-- cannot run DD forms unless logged on as 'viewpointcs'
select @user = suser_sname()	-- current user name
if @mod = 'DD' and @user <> 'viewpointcs'
	begin
	select @errmsg = 'Must use the ''viewpointcs'' login to access DD forms!', @rcode = 1
	goto vspexit
	end

if @user = 'viewpointcs' 
	begin
	select @errmsg = 'user is viewpointcs'
	set @attachmentSecurityLevel = 2 -- Viewpoint login has full access
	goto vspexit	
	end

-- 1st check: Attachment security level check for user and active company, Security Group -1 
select @attachmentSecurityLevel = AttachmentSecurityLevel
from dbo.vDDFS with (nolock) 
where Co = @co and Form = @secureform and SecurityGroup = -1 and VPUserName = @user

if @attachmentSecurityLevel is not null		
	goto vspexit		
	
-- 2nd check: Attachment security level check for user across all companies, Security Group -1 and Company = -1
select @attachmentSecurityLevel = AttachmentSecurityLevel
from dbo.vDDFS with (nolock) 
where Co = -1 and Form = @secureform and SecurityGroup = -1 and VPUserName = @user

if @attachmentSecurityLevel is not null		
	goto vspexit		
	
-- 3rd check: Attachment security level check for groups that user is a member of within active company
-- Get record level permissions, use least restrictive option from any group the user belongs to at this access level 		
IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = @co and f.Form = @secureform and s.VPUserName = @user
				and f.AttachmentSecurityLevel = 0) set @attachmentSecurityLevel = 0
IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = @co and f.Form = @secureform and s.VPUserName = @user
				and f.AttachmentSecurityLevel = 1) set @attachmentSecurityLevel = 1
IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = @co and f.Form = @secureform and s.VPUserName = @user
				and f.AttachmentSecurityLevel = 2) set @attachmentSecurityLevel = 2								
				
if @attachmentSecurityLevel is not null		
	goto vspexit		
					
-- 4th check: Attachment security level check for groups that user is a member of across all companies, Company = -1
-- Get record level permissions, use least restrictive option from any group the user belongs to at this access level 		
if exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user 
				and f.AttachmentSecurityLevel = 0) set @attachmentSecurityLevel = 0
if exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user 
				and f.AttachmentSecurityLevel = 1) set @attachmentSecurityLevel = 1
if exists(select top 1 1 from dbo.vDDFS f with (nolock)
			join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
			where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user 
				and f.AttachmentSecurityLevel = 2) set @attachmentSecurityLevel = 2			
	
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFormAttachmentSecurityLevel]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFormAttachmentSecurityLevel] TO [public]
GO
