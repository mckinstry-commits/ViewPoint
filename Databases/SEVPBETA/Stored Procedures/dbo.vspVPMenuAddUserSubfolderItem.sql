SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE              PROCEDURE [dbo].[vspVPMenuAddUserSubfolderItem]
/**************************************************
* Created:  JK 06/11/03 - VP.NET
* Modified: JK 07/29/03
* Modified: JK 12/10/03 - Added @co.
*
* Used by VPMenu to add an item to a menu following a drag-drop.
* The items represent a shortcuts to forms the user is permitted to access.
* Only the "My ViewPoint" and the module-level (eg, "AP") menu items (nodes)
* can have items dropped on them.  
*
* The key of DDSI is  username + mod + itemtype + menuitem.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*	@co			Needed since we created company-specific menu subfolder.
*       @username		Needed since we use a system connection.
*	@subfolder 		smallint
*	@mod 			2-char
*	@itemtype 		'F' (form) or 'R' (report)
*	@menuitem 		form name or report id
*	@menuseq		Optional sequence number used to order the forms
*
* Output
*	@errmsg
*
****************************************************/
	(@co bCompany = null, @username varchar(128) = null, @mod char(2), 
	 @subfolder smallint = null,
	 @itemtype char(1) = null, @menuitem varchar(30) = null, 
	 @menuseq smallint = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null or @username is null or @subfolder is null or @mod is null or @itemtype is null or @menuitem is null) 
	begin
	select @errmsg = 'Missing required field:  co, username, mod, subfolder, itemtype or menuitem.', @rcode = 1
	goto vspexit
	end

if @co = 0 and (@username = '')  -- Cannot test for @mod='' because My Viewpoint passes in 2 spaces, but they get trimmed off.
	begin
	select @errmsg = 'Cannot have empty username or mod when co = 0.', @rcode = 2
	goto vspexit
	end

if @co > 0 and (@username <> '' or @mod <> '')
	begin
	select @errmsg = 'Cannot have non-empty username or mod when co > 0.', @rcode = 3
	goto vspexit
	end

-- Insert a row with the supplied data.
INSERT INTO DDSI (Co, VPUserName, Mod, SubFolder, ItemType, MenuItem, MenuSeq)
VALUES (@co, @username, @mod, @subfolder, @itemtype, @menuitem, @menuseq)
   
vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuAddUserSubfolderItem] TO [public]
GO
