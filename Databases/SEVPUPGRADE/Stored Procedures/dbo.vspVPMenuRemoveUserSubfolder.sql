SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE              PROCEDURE [dbo].[vspVPMenuRemoveUserSubfolder]
/**************************************************
* Created:  JK 07/22/03
* Modified:
*
* Used by VPMenu to remove a subfolder (from DDSF) and all subfolder items (from DDSI)
* that are associated with the specified subfolder.
*
* The key of DDSF and DDSI is  username + mod + subfolder.
*
* Inputs
*       @username		Needed since we use a system connection.
*	@mod			2-chars.  "  " for My Viewpoint.
*	@subfolder 		smallint id of the folder for the user+mod
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @mod char(2) = null, @subfolder smallint = null, 
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @mod is null or @subfolder is null) 
	begin
	select @errmsg = 'Missing required field:  username, mod or subfolder.', @rcode = 1
	goto vspexit
	end

-- Delete any items in DDSI associated with this subfolder.
DELETE FROM DDSI WHERE VPUserName = @username AND Mod = @mod AND SubFolder = @subfolder


-- Delete a row with the supplied data.
DELETE FROM DDSF WHERE VPUserName = @username AND Mod = @mod AND SubFolder = @subfolder

vspexit:
	return @rcode












GO
GRANT EXECUTE ON  [dbo].[vspVPMenuRemoveUserSubfolder] TO [public]
GO
