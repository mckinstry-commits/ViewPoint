SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE           PROCEDURE [dbo].[vspVPMenuDeleteSubFolderItem]
/**************************************************
* Created:  JK 06/16/03 - VP.NET
* Modified:
*
* Used by VPMenu to delete an item from a menu for a Cut or Delete menu action.
* The items represent a shortcuts to forms the user is permitted to access.
* Only the "My ViewPoint" and the module-level (eg, "AP") menu items (nodes)
* can have items deleted from them.  
*
* The key of DDSI is  username + mod + itemtype + menuitem.
*
* Inputs
*	@username		Needed since we use the system connection.
*	@mod			2-char
*	@subfolder		Numeric id of subfolder for specified module.
*	@itemtype 		'F' (form) or 'R' (report)
*	@menuitem 		form name or report id
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @mod char(2) = null, 
	 @subfolder smallint = null , @itemtype char(1) = null,
	 @menuitem varchar(30) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @mod is null or @subfolder is null or @itemtype is null or @menuitem is null) 
	begin
	select @errmsg = 'Missing required field:  username, mod, subfolder, itemtype or menuitem.', @rcode = 1
	goto vspexit
	end


-- Delete the row with the supplied data.
DELETE FROM DDSI WHERE VPUserName=@username and Mod = @mod and SubFolder=@subfolder and ItemType=@itemtype and MenuItem=@menuitem
   
vspexit:
	return @rcode









GO
GRANT EXECUTE ON  [dbo].[vspVPMenuDeleteSubFolderItem] TO [public]
GO
