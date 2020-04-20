SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE             PROCEDURE [dbo].[vspVPMenuRenameUserSubfolder]
/**************************************************
* Created:  JK 07/30/03
* Modified:
*
* Used by VPMenu to rename a user-defined subfoler in the tree.
*
* The key of DDSF is  username + mod + subfolder (smallint).  We will
* change the Title field only.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @username		Needed since we use a system connection.
*	@mod 			2-char module name we're adding the subfolder to.
*	@subfolder		smallint
*	@title			New title for the subfolder. Up to 30 chars.
*
* Output
*	@errmsg
*
****************************************************/
	(@username varchar(128) = null, @mod char(2) = null, @subfolder smallint, 
	 @title varchar(30) = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@username is null or @mod is null or @subfolder is null or @title is null) 
	begin
	select @errmsg = 'Missing required field:  username, mod, subfolder or title.', @rcode = 1
	goto vspexit
	end

-- Subfolder has to be a value > 0.  (0 means a root-level folder, which isn't
-- a subfolder.)

if (@subfolder < 1)
	begin
	select @errmsg = 'Subfolder is less than 1.', @rcode=2
	goto vspexit
	end


-- Insert a row with the supplied data.
UPDATE DDSF SET Title = @title
WHERE VPUserName = @username AND Mod = @mod AND SubFolder = @subfolder
   
vspexit:
	return @rcode











GO
GRANT EXECUTE ON  [dbo].[vspVPMenuRenameUserSubfolder] TO [public]
GO
