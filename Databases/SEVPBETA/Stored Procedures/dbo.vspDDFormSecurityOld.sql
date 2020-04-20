SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create PROCEDURE [dbo].[vspDDFormSecurityOld]
/********************************************************
* Created: GG 07/11/03
* Modified: GG 07/15/04 - add primary Module 'active' check
*			GG 01/21/05 - allow all Company entries (Co=-1)
*			GG 04/10/06 - mods for Mod and Form LicLevel
*			GG 03/12/07 - use least restrictive record level permissions
*			GG 09/05/07 - #125347 - mods for security form
*			JonathanP 02/25/09 - #132390 - Updated to handle attachment security level column in DDFS
*
* Used to determine program security level for a specific 
* form and user.
*
* Inputs:
*	@co		Active Company#
*	@form	Form name
*	
* Outputs:
*	@access				Access level 0 = full, 1 = by tab, 2 = denied, null = missing
*	@recadd				Record Add option (Y/N)
*	@recupdate			Record Update option (Y/N)
*	@recdelete 			Record Delete option (Y/N)
*   @attachmentSecurityLevel	0 = Add, 1 = Add/Edit, 2 = Add/Edit/Delete, -1 = None
*	@errmsg				Message
*
* Return Code:
*	@rcode		0 = success, 1 = error
*
*********************************************************/

	(@co bCompany = null, @form varchar(30) = null, @access tinyint output,
	 @recadd bYN = null output, @recupdate bYN = null output, @recdelete bYN = null output, 
	 @attachmentSecurityLevel int = null OUTPUT, @errmsg varchar(512) output)
as

set nocount on

declare @rcode int, @user bVPUserName, @mod char(2), @modliclevel tinyint, @formliclevel tinyint,
	@secureform varchar(30), @detailsecurity bYN

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
--check for security override, if set use current not security form
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

-- make sure the forms' primary module is active and check license level
select @mod = m.Mod, @modliclevel = m.LicLevel, @formliclevel = f.LicLevel
from dbo.vDDMO m (nolock)
join dbo.DDFHShared f on f.Mod = m.Mod
where f.Form = @secureform and m.Active = 'Y'

if @@rowcount = 0 
	begin
	select @errmsg = 'Primary module for this form is not active!', @rcode = 1
	goto vspexit
	end

-- cannot run DD forms unless logged on as 'viewpointcs'
select @user = suser_sname()	-- current user name
if @mod = 'DD' and @user <> 'viewpointcs'
	begin
	select @errmsg = 'Must use the ''viewpointcs'' login to access DD forms!', @rcode = 1
	goto vspexit
	end

-- initialize return params
select @rcode = 0, @access = 0, @recadd = 'Y', @recupdate = 'Y', @recdelete = 'Y', @attachmentSecurityLevel = 2

if @user = 'viewpointcs' 
	begin
	select @errmsg = 'user is viewpointcs'
	goto vspexit	-- Viewpoint login has full access
	end

--check Module and Form license levels - don't return error but deny access
if @formliclevel > @modliclevel
	begin
	select @errmsg = 'Module/Form license level violation.', @access = 2, @recadd = 'N', @recupdate = 'N', @recdelete = 'N', @attachmentSecurityLevel = -1
	goto vspexit
	end

-- 1st check: Form security for user and active company, Security Group -1 
select @access = Access, @recadd = RecAdd, @recupdate = RecUpdate, @recdelete = RecDelete, @attachmentSecurityLevel = AttachmentSecurityLevel
from dbo.vDDFS with (nolock) 
where Co = @co and Form = @secureform and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
		if @access in (0,1) 
		begin
			select @errmsg = '@access is 0 or 1.'
			goto vspexit	-- full or tab level access
		end
		if @access = 2	-- form access denied
		begin
			select @errmsg = @user + ' has been denied access to the ' + @secureform + ' form!'
			goto vspexit
		end
		select @errmsg = 'Invalid access value assigned to the ' + @secureform + ' form for ' + @user
		goto vspexit
	end
-- 2nd check: Form security for user across all companies, Security Group -1 and Company = -1
select @access = Access, @recadd = RecAdd, @recupdate = RecUpdate, @recdelete = RecDelete, @attachmentSecurityLevel = AttachmentSecurityLevel
from dbo.vDDFS with (nolock) 
where Co = -1 and Form = @secureform and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
	if @access in (0,1) 
		begin
		select @errmsg = '@access is 0 or 1.'
		goto vspexit	-- full or tab level access
		end
	if @access = 2	-- form access denied
		begin
		select @errmsg = @user + ' has been denied access to the ' + @secureform + ' form!'
		goto vspexit
		end
	select @errmsg = 'Invalid access value assigned to the ' + @secureform + ' form for ' + @user
	goto vspexit
	end
	
-- 3rd check: Form security for groups that user is a member of within active company
select @access = null
select @access = min(Access)	-- get least restrictive access level
from dbo.vDDFS f with (nolock)
join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
where f.Co = @co and f.Form = @secureform and s.VPUserName = @user
if @access in (0,1)		-- full access or tab level access
	begin
	-- get record level permissions, use least restrictive option from any group the user
	--										belongs to at this access level 
	select @recadd = 'N', @recupdate = 'N', @recdelete = 'N', @attachmentSecurityLevel = -1
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecAdd = 'Y') set @recadd = 'Y'
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecUpdate = 'Y') set @recupdate = 'Y'
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecDelete = 'Y') set @recdelete = 'Y'
	IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 0) set @attachmentSecurityLevel = 0
	IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 1) set @attachmentSecurityLevel = 1
	IF exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = @co and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 2) set @attachmentSecurityLevel = 2
	select @errmsg = '@access is 0 or 1.'
	goto vspexit
	end
if @access = 2	-- access denied
	begin
	select @errmsg = @user + ' has been denied access to the ' + @secureform + ' form!'
	goto vspexit
	end
if @access is not null
	begin
	select @errmsg = 'Invalid access value assigned to the ' + @secureform + ' form for ' + @user, @rcode = 1
	goto vspexit
	end
-- 4th check: Form security for groups that user is a member of across all companies, Company = -1
select @access = min(Access)	-- get least restrictive access level
from dbo.vDDFS f with (nolock)
join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user
if @access is null		-- no entries for user in any security group
	begin
	select @errmsg = @user + ' has not been setup with access to the ' + @secureform + ' form!'
	goto vspexit
	end
if @access in (0,1)		-- full access or tab level access
	begin
	-- get record level permissions, use least restrictive option from any group the user
	--										belongs to at this access level 
	select @recadd = 'N', @recupdate = 'N', @recdelete = 'N', @attachmentSecurityLevel = -1
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecAdd = 'Y') set @recadd = 'Y'
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecUpdate = 'Y') set @recupdate = 'Y'
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.RecDelete = 'Y') set @recdelete = 'Y'	
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 0) set @attachmentSecurityLevel = 0
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 1) set @attachmentSecurityLevel = 1
	if exists(select top 1 1 from dbo.vDDFS f with (nolock)
				join dbo.vDDSU s with (nolock) on s.SecurityGroup = f.SecurityGroup 
				where f.Co = -1 and f.Form = @secureform and s.VPUserName = @user and f.Access = @access
					and f.AttachmentSecurityLevel = 2) set @attachmentSecurityLevel = 2

	select @errmsg = '@access is 0 or 1; multiple groups.'
	goto vspexit
	end
if @access = 2	-- access denied
	begin
	select @errmsg = @user + ' has been denied access to the ' + @secureform + ' form!'
	goto vspexit
	end
select @errmsg = 'Invalid access value assigned to the ' + @secureform + ' form for ' + @user
goto vspexit
	
	
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDFormSecurity]'
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspDDFormSecurityOld] TO [public]
GO
