SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[vspDDTabSecurity]
/********************************************************
 * Created: GG 06/10/03
 * Modified: GG 09/30/04 - treat invalid or missing access as denied
 *			GG 01/21/05 - allow all Company entries (Co=-1)
 *
 * Used to determine tab security level for a specific 
 * form and user.  Assumes form is secured by tab.
 *
 * Inputs:
 *	@co			Active Company#
 *	@form		Form name
 *	@tab		Tab #
 *	
 * Outputs:
 *	@access		Access levels 0 = full, 1 = read only, 2 = denied
 *	@errmsg		Error message
 *
 * Return Code:
 *	@rcode		0 = success, 1 = error
 *
 *********************************************************/

	(@co bCompany = null, @form varchar(30) = null, @tab tinyint = null, 
	 @access tinyint output, @errmsg varchar(512) output)
as

set nocount on

declare @rcode int, @user bVPUserName, @mod char(2)

if @co is null or @form is null or @tab is null
	begin
	select @errmsg = 'Missing required input parameters: Company #, Form, and/or Tab #!', @rcode = 1
	goto vspexit
	end

-- initialize return params
select @rcode = 0, @access = 0

select @user = suser_sname()	-- current user name
if @user = 'viewpointcs' goto vspexit	-- Viewpoint login has full access

-- 1st check: Tab security for user and active company, Security Group = -1
select @access = Access
from dbo.vDDTS (nolock)
where Co = @co and Form = @form and Tab = @tab and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
	if @access in (0,1,2) goto vspexit		-- full, read only, or access denied
	--select @errmsg = 'Invalid access value assigned to the ' + @form + ' form and Tab# ' 
		--+ convert(varchar,@tab) + ' for ' + @user, @rcode = 1
	select @access = 2	-- treat invalid access as 'denied'
	goto vspexit
	end
-- 2nd check: Tab security for user and all companies, Security Group = -1 and Company = -1
select @access = Access
from dbo.vDDTS (nolock)
where Co = -1 and Form = @form and Tab = @tab and SecurityGroup = -1 and VPUserName = @user
if @@rowcount = 1
	begin
	if @access in (0,1,2) goto vspexit		-- full, read only, or access denied
	--select @errmsg = 'Invalid access value assigned to the ' + @form + ' form and Tab# ' 
		--+ convert(varchar,@tab) + ' for ' + @user, @rcode = 1
	select @access = 2	-- treat invalid access as 'denied'
	goto vspexit
	end
-- 3rd check: Tab security for groups that user is a member of within active company
select @access = null
select @access = min(Access)	-- get least restrictive access level
from dbo.vDDTS t (nolock)
join dbo.vDDSU s (nolock) on s.SecurityGroup = t.SecurityGroup 
where t.Co = @co and t.Form = @form and t.Tab = @tab and s.VPUserName = @user
if @access in (0,1,2) goto vspexit		-- full, read only, or access denied
--select @errmsg = 'Invalid access value assigned to the ' + @form + ' form and Tab# ' 
	--	+ convert(varchar,@tab) + ' for ' + @user, @rcode = 1
if @access is not null
	begin
	select @access = 2	-- treat invalid access as 'denied'
	goto vspexit
	end
-- 4th check: Tab security for groups that user is a member across all companies, Company = -1
select @access = min(Access)	-- get least restrictive access level
from dbo.vDDTS t (nolock)
join dbo.vDDSU s (nolock) on s.SecurityGroup = t.SecurityGroup 
where t.Co = -1 and t.Form = @form and t.Tab = @tab and s.VPUserName = @user
if @access is null		-- no entries for user in any security group
	begin
	--select @errmsg = @user + ' has not been setup with access to the ' + @form + ' form and Tab# '
	--	+ convert(varchar,@tab), @rcode = 1
	select @access = 2	-- treat missing entry as 'denied'
	goto vspexit
	end
if @access in (0,1,2) goto vspexit		-- full, read only, or access denied
--select @errmsg = 'Invalid access value assigned to the ' + @form + ' form and Tab# ' 
	--	+ convert(varchar,@tab) + ' for ' + @user, @rcode = 1
select @access = 2	-- treat invalid access as 'denied'

goto vspexit

	
vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDTabSecurity]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDTabSecurity] TO [public]
GO
