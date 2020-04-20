SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspOverwriteMyTaskSubFolderItems]
/**************************************************  
* Created:  Dave C 06/04/09  
* Modified:  
*  
* Used by VACopyUserTemplate to write new folders items to a user's
* MyTask Folder
*  
* Inputs:
* @username = VPUserName
* @subfolder = smallint
* @itemtype char
* @menuitem varchar(30)
*
* Outputs:
* @errmsg  
*  
****************************************************/  
 (@username bVPUserName, @subfolder smallint, @itemtype char,
  @menuitem varchar(30), @errmsg varchar(512) output)
 
AS
  
SET NOCOUNT ON

DECLARE @co bCompany, @mod char
SELECT @co = 0, @mod = ''
  
-- Check for required fields  
IF (@username is null or @subfolder is null or @itemtype is null or @menuitem is null)   
	BEGIN
		SELECT @errmsg = 'Missing required field:  username, subfolder, itemtype or menutype.'
		GOTO vspexit  
	END
		
INSERT INTO DDSI	(Co, VPUserName, Mod, SubFolder, ItemType, MenuItem) Values
					(@co, @username, @mod, @subfolder, @itemtype, @menuitem)

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspOverwriteMyTaskSubFolderItems] TO [public]
GO
