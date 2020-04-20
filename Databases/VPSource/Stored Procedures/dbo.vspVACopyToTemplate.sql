SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================  
-- Author:  Dave C, [vspVACopyToTemplate] 
-- Create date: 6/5/09 
-- Description: inserts custom template into DDTFShared
-- =============================================  
CREATE PROCEDURE [dbo].[vspVACopyToTemplate]
(@title bDesc, @mod char(2), @foldertemplate smallint output, @errmsg varchar(512) output)
   
AS  

SET NOCOUNT ON

-- Default new Templates to visible
DECLARE @active bYN
SELECT @active = 'Y'

-- Check for null values
IF (@title is null or @mod is null)   
	BEGIN
		SELECT @errmsg = 'Missing required field:  username, title.'
		GOTO vspexit  
	END
	
-- Check for unique Template Title
IF EXISTS(SELECT TOP 1 1 FROM DDTFShared
		  WHERE Title = @title
		  )
	BEGIN
		SELECT @errmsg = 'Duplicate Template Title name.'
		GOTO vspexit
	END

	  
-- Set template number
SELECT @foldertemplate = MAX(FolderTemplate)+ 1 FROM DDTFShared

--Check for custom templates: they start at 10,000
IF @foldertemplate < 10000
	BEGIN
		--If no custom templates, set this new template as the first
		SELECT @foldertemplate = 10000
	END

INSERT INTO DDTFShared
	(FolderTemplate, Title, [Mod], Active) VALUES
	(@foldertemplate, @title, @mod, @active)

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspVACopyToTemplate] TO [public]
GO
