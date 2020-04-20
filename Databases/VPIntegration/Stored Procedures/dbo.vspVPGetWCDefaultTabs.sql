SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: Chris G 03/29/2011 B-02317
* MODIFIED BY: Huy H 11/27/2012 B-11081 added RefreshInterval
*
*
*
*
* Usage: Gets all default tabs for the given display ID.
*
* Input params:
*	@displayID
*
* Output params:
*	List of tabs
*
* Return code:
*	
************************************************************/
CREATE PROCEDURE [dbo].[vspVPGetWCDefaultTabs] 
	@displayID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT 
		VPDisplayTabs.KeyID, 
		VPDisplayTabs.TabNumber, 
		VPDisplayTabs.TabName, 
		VPDisplayTabs.TemplateName, 
		VPCanvasSettingsTemplate.GroupID,
		VPCanvasSettingsTemplate.RefreshInterval
    FROM VPDisplayTabs
    INNER JOIN VPCanvasSettingsTemplate ON VPCanvasSettingsTemplate.TemplateName = VPDisplayTabs.TemplateName
    WHERE DisplayID = @displayID
    ORDER BY TabNumber
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetWCDefaultTabs] TO [public]
GO
