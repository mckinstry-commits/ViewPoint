SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE               PROCEDURE [dbo].[vspVPMenuAddUserSubfolder]
/**************************************************
* Created:  JK 07/22/03
* Modified:
*
* Used by VPMenu to add a subfoler in the tree.
*
* The key of DDSF is  username + mod + subfolder (smallint).  We have to determine the
* value of subfolder to use by getting the max value in use for the user+mod.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @co			Company number.
*       @username		Needed since we use a system connection.
*	@mod 			2-char module name we're adding the subfolder to.
*	@title			Up to 30 chars.
*
* Output
*	@subfolder		The value assigned to the subfolder we just added.
*	@errmsg
*
****************************************************/
	(@co tinyint = null, @username varchar(128) = null, @mod char(2) = null, @title varchar(30) = null,
	 @subfolder smallint output, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@co is null or @username is null or @mod is null or @title is null) 
	begin
	select @errmsg = 'Missing required field:  co, username, mod or title.', @rcode = 1
	goto vspexit
	end

-- What is the max SubFolder value in use by this combination of user+mod.

SELECT @subfolder = MAX (SubFolder) FROM DDSF WHERE VPUserName = @username AND Mod = @mod AND Co = @co

--print 'Max = ' + CONVERT(nvarchar, @subfolder)

-- Increment the value.
select @subfolder = ISNULL(@subfolder,0) + 1

--print 'After adding = ' + CONVERT(nvarchar, @subfolder)

-- Insert a row with the supplied data.
INSERT INTO DDSF (Co, VPUserName, Mod, SubFolder, Title)
VALUES (@co, @username, @mod, @subfolder, @title)
   
vspexit:
	return @rcode













GO
GRANT EXECUTE ON  [dbo].[vspVPMenuAddUserSubfolder] TO [public]
GO
