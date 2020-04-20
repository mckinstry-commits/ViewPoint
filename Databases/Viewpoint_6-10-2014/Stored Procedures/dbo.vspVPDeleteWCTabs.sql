SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: CJG 02/21/2011
* MODIFIED BY: 
*
*
*
*
* Usage: Deletes all work center tabs for the user
*
* Input params:
*	@username
*
* Output params:
*	List of configs
*
* Return code:
*	
************************************************************/
CREATE PROCEDURE [dbo].[vspVPDeleteWCTabs] 
	@username bVPUserName
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Don't delete the static My Viewpoint tab
    DELETE FROM VPCanvasSettings WHERE VPUserName = @username AND TabNumber > 1;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPDeleteWCTabs] TO [public]
GO
