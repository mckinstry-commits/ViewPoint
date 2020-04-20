SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE                  PROCEDURE [dbo].[vspVPMenuDoSubfolders]
/**************************************************
* Created:  JK 05/11/04
* Modified:
*
* Calls other stored procs in order to reduce the number of calls.
* Input is company number and username.
* There is no output except for the rcode and errmsg.
* 
* Inputs
*       @co
*	@username	
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @username varchar(128), @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

if (@co is null) or (@username is null) 
	begin
	select @errmsg = 'Missing required field:  company or username.', @rcode = 1
	goto vspexit
	end

--
exec @rcode = vspVPMenuAddCompanyFolderRecord @co, @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuAddCompanyFolderRecord] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuAddCompanyFolderRecord] @errmsg = ' + @errmsg
	goto vspexit
	end
--print 'vspVPMenuAddCompanyFolderRecord completed successfully.'
--

exec @rcode = vspVPMenuAddSubFoldersZero @username, @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuAddSubFoldersZero] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuAddSubFoldersZero] @errmsg = ' + @errmsg
	goto vspexit
	end
--print 'vspVPMenuAddSubFoldersZero completed successfully.'
--

exec @rcode = vspVPMenuGetCompanySubFolders @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuGetCompanySubFolders] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuGetCompanySubFolders] @errmsg = ' + @errmsg
	goto vspexit
	end
--print 'vspVPMenuGetCompanySubFolders completed successfully.'
--

exec @rcode = vspVPMenuGetSubFolders @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuGetSubFolders] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuGetSubFolders] @errmsg = ' + @errmsg
	goto vspexit
	end
--print 'vspVPMenuGetSubFolders completed successfully.'
--
--print 'vspVPMenuGetSubFolders completed successfully.'
--

exec @rcode = vspVPMenuGetModules @co, @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuGetModules] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuGetModules] @errmsg = ' + @errmsg
	goto vspexit
	end

-- exec @rcode = vspVPMenuGetPredefinedSubFolders @errmsg

exec @rcode = vspVPMenuGetAllSubfolderTemplates @errmsg

if (@rcode <> 0)
	begin
	select @errmsg = '[vspVPMenuGetPredefinedSubFolders] Non-zero rcode returned:  ' + STR(@rcode)
	goto vspexit
	end
if (@errmsg <> '')
	begin
	select @errmsg = '[vspVPMenuGetPredefinedSubFolders] @errmsg = ' + @errmsg
	goto vspexit
	end



vspexit:
	return @rcode










GO
GRANT EXECUTE ON  [dbo].[vspVPMenuDoSubfolders] TO [public]
GO
