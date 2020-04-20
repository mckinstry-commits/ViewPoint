SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Dave C, [vspVACopyItemsToTemplate] 
-- Create date: 6/5/09 
-- Description: inserts template items into DDTDShared
-- =============================================  
CREATE PROCEDURE [dbo].[vspVACopyItemsToTemplate]
(@foldertemplate smallint, 
@itemtype char, 
@menuitem varchar(30), 
@errmsg varchar(512) output)
   
AS  

SET NOCOUNT ON;  

-- Check for null values
IF (@foldertemplate is null or @itemtype is null or @itemtype is null or @menuitem is null)   
	BEGIN
		SELECT @errmsg = 'Missing required field:  username, title.'
		GOTO vspexit  
	END
	
-- Check that Template Item is unique 
IF EXISTS(SELECT TOP 1 1 FROM DDTDShared
		  WHERE FolderTemplate = @foldertemplate and
				ItemType = @itemtype and
				MenuItem = @menuitem
		  )
	BEGIN
		SELECT @errmsg = 'Duplicate Template Item.'
		GOTO vspexit
	END

INSERT INTO DDTDShared
	(FolderTemplate, ItemType, MenuItem) VALUES
	(@foldertemplate, @itemtype, @menuitem)

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspVACopyItemsToTemplate] TO [public]
GO
