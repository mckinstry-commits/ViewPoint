SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspOverwriteMyTaskSubFolder]
/**************************************************  
* Created:  Dave C 06/04/09  
* Modified:  
*  
* Used by VACopyUserTemplate to clear a write new folders to a user's
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

BEGIN TRAN
	BEGIN TRY
		
		-- My Tasks SubFolder # = 0; it should always exist
		SELECT @subfolder =	MAX(SubFolder) FROM DDSF
							WHERE	[Mod] = @mod and
									VPUserName = @username and
									Co = @co
		
		SELECT @subfolder =	ISNULL(@subfolder, 0) + 1
		
		INSERT INTO DDSF	(Co, VPUserName, [Mod], SubFolder, Title)
							VALUES (@co, @username, @mod, @subfolder, @title)
		
		-- Check for duplicate records							
		IF (SELECT COUNT(*) FROM DDSF
							WHERE Title = @title and
							[Mod] = @mod and
							VPUserName = @username and
							Co = @co) > 1
							
		-- Jump to Catch with Serverity > 10
		RAISERROR('Duplicate Folder entry in DDSF', 11, 1)
			
	END TRY
	
	BEGIN CATCH
	
		ROLLBACK TRAN
		SELECT @errmsg = 'Duplicate Folder entry in DDSF'
		
	END CATCH
	
COMMIT TRAN

RETURN @subfolder

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspOverwriteMyTaskSubFolder] TO [public]
GO
