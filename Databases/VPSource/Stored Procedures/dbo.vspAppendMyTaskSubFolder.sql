SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspAppendMyTaskSubFolder]
/**************************************************  
* Created:  Dave C 06/04/09  
* Modified:  
*  
* Used by VACopyUserTemplate to append new folders to a user's
* MyTask Folder
*  
* Inputs:
* @username = VPUserName
* @title = bDesc
* 
*
* Outputs:
* @errmsg  
* @subfolder
*  
****************************************************/  
 (@username bVPUserName, @title bDesc,
 @subfolder smallint output, @errmsg varchar(512) output)  
 
AS
  
SET NOCOUNT ON

DECLARE @co bCompany, @mod char
SELECT @co = 0, @mod = ''
  
-- Check for required fields  
IF (@username is null or @title is null)   
	BEGIN
		SELECT @errmsg = 'Missing required field:  username, title.'
		GOTO vspexit  
	END

-- Check for duplicate Folder titles
IF (SELECT COUNT(*) FROM DDSF
	WHERE Title = @title and
		  [Mod] = @mod and
		  VPUserName = @username and
		  Co = @co) > 1
		  
		  BEGIN
				SELECT @errmsg = 'Duplicate Folder found in DDSF'
				GOTO vspexit
		  END
	

-- Check if a folder already exists in a user's My Tasks. If so, retrieve the SubFolder #
SELECT @subfolder =	(SELECT SubFolder FROM DDSF
					 WHERE	Title = @title and
							[Mod] = @mod and
							VPUserName = @username and
							Co = @co)

-- If the folder does exist use it, if not increment the current highest SubFolder # by 1
SELECT @subfolder =	ISNULL(@subfolder,
							(SELECT MAX(SubFolder)+1 FROM DDSF
							 WHERE [Mod] = @mod and
							 VPUserName = @username and
							 Co = @co))
							 
--Check @subfolder for Null--this value can result if NOTHING is in DDSF for the user
IF @subfolder is null
	BEGIN
		SELECT @errmsg = 'VP User: ' + @username + ' does not have a My Tasks folder in DDSF'
		GOTO vspexit
	END

-- If the does not exist, add it
IF NOT EXISTS(
			SELECT TOP 1 1 FROM DDSF
			WHERE SubFolder = @subfolder and
			[Mod] = @mod and
			VPUserName = @username and
			Co = @co
			 )
	BEGIN
		INSERT INTO DDSF	(Co, VPUserName, [Mod], SubFolder, Title) VALUES
							(@co, @username, @mod, @subfolder, @title)
	END

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspAppendMyTaskSubFolder] TO [public]
GO
