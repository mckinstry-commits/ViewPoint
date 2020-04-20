SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPRetrieveUsersUsingQuery]
/***********************************************************
* CREATED BY:   HH 5/29/2012
* MODIFIED BY:  
*
* Usage: Retrieve Users that added a VA Inquiry to a WorkCenter/MyVP
*	
*
* Input params:
*	@QueryName
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/

@QueryName VARCHAR(50) = NULL		
,@msg VARCHAR(100) OUTPUT
,@ReturnCode INT OUTPUT  	
AS

SET NOCOUNT ON

BEGIN TRY
	
	;WITH cte
	AS 
	(
		-- MyVP users & tabs
		SELECT DISTINCT VPCanvasSettings.VPUserName, VPCanvasSettings.TabName  
		FROM dbo.VPCanvasGridSettings 
			INNER JOIN VPPartSettings on VPCanvasGridSettings.PartId = VPPartSettings.KeyID
			INNER JOIN VPCanvasSettings on VPPartSettings.CanvasId = VPCanvasSettings.KeyID
		WHERE VPCanvasGridSettings.QueryName = @QueryName and VPCanvasSettings.TemplateName like '%Grid%'

		UNION ALL

		-- WC users & tabs
		SELECT DISTINCT VPCanvasSettings.VPUserName, VPCanvasSettings.TabName  
		FROM dbo.VPCanvasTreeItems
			INNER JOIN VPCanvasSettings on VPCanvasTreeItems.CanvasId = VPCanvasSettings.KeyID
		where VPCanvasTreeItems.Item = @QueryName
		
	)
	SELECT DISTINCT VPUserName, TabName
	FROM cte
	ORDER BY VPUserName, TabName  
	

	SELECT	@msg = 'Users retrieved.',@ReturnCode = 0
	RETURN @ReturnCode;

END TRY
BEGIN CATCH
    SELECT	@msg = 'vspVPRetrieveUsersUsingQuery failed',@ReturnCode = 1
	RETURN @ReturnCode
END CATCH; 
GO
GRANT EXECUTE ON  [dbo].[vspVPRetrieveUsersUsingQuery] TO [public]
GO
