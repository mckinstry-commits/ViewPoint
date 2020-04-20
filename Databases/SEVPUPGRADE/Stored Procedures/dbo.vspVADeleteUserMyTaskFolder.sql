SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVADeleteUserMyTaskFolder]
/**************************************************  
* Created:  Dave C 06/04/09  
* Modified:  
*  
* Used by VACopyUserTemplate to clear a user's MyTask Folder
*  
* Inputs:
* @username = VPUserName
*
* Outputs:
* @errmsg
*  
****************************************************/  
 (@username bVPUserName, @errmsg varchar(512) output)  
 
AS
  
SET NOCOUNT ON

-- Company 0 is used for user's My Tasks
DECLARE @co bCompany, @mod char
SELECT @co = 0, @mod = ''
  
-- Check for required fields  
IF (@username is null)   
	BEGIN
		SELECT @errmsg = 'Missing required field:  username.'
		GOTO vspexit  
	END

-- Cascade delete Items and then Folders
BEGIN TRAN
	BEGIN TRY
		DELETE FROM DDSI
		WHERE	[Mod] = @mod and
				VPUserName = @username and
				[Co] = @co

		DELETE FROM DDSF
		WHERE	[Mod] = @mod and
				VPUserName = @username and
				[Co] = @co and
				SubFolder <> 0
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRAN
		SELECT @errmsg = 'Removing items from DDSI and/or DDSF was unsuccessful'
	END CATCH
	
COMMIT TRAN

vspexit:
GO
GRANT EXECUTE ON  [dbo].[vspVADeleteUserMyTaskFolder] TO [public]
GO
