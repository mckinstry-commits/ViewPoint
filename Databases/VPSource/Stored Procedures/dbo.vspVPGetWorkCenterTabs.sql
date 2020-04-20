SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:	CJG 02/21/2011
* MODIFIED BY:	CC 2011-04-17 removed offset, all WC tabs (including my viewpoint) are loaded from here
*				CC 2011-05-19 made stored proc self-healing to fix out of sequence tabs.
*				CC 2011-05-24 Added a maxTabNumber parameter to limit the number of tabs returned based on site settings
*				HH 2012-11-27 B-11081 added RefreshInterval to selection
*
*
*
*
* Usage: Loads all the Work Center tab configurations
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
CREATE PROCEDURE [dbo].[vspVPGetWorkCenterTabs] 
	@username bVPUserName,
	@maxTabNumber INT = 6
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--If for some reason the tabs get out of sequence, this update statement heals them and puts them in order again
	WITH tabs
	AS
	(
		SELECT	TabNumber,
				TabName, 
				VPCanvasSettings.TemplateName as TemplateName,
				VPCanvasSettings.KeyID as KeyID,
				VPCanvasSettingsTemplate.GroupID as GroupID,
				VPUserName,
				ROW_NUMBER() OVER (PARTITION BY VPUserName ORDER BY VPUserName, TabNumber) AS RowNumber
		FROM VPCanvasSettings
		LEFT OUTER JOIN VPCanvasSettingsTemplate ON VPCanvasSettingsTemplate.TemplateName = VPCanvasSettings.TemplateName
	)
	UPDATE VPCanvasSettings
	SET VPCanvasSettings.TabNumber = tabs.RowNumber
	FROM dbo.VPCanvasSettings
	INNER JOIN tabs ON dbo.VPCanvasSettings.KeyID = tabs.KeyID
	WHERE tabs.RowNumber <> tabs.TabNumber AND VPCanvasSettings.VPUserName = @username;
			
    SELECT	TabNumber,
			TabName, 
			VPCanvasSettings.RefreshInterval,
			VPCanvasSettings.TemplateName AS TemplateName,
			VPCanvasSettings.KeyID AS KeyID,
			COALESCE(VPCanvasSettingsTemplate.GroupID, 1) AS GroupID
    FROM VPCanvasSettings
    LEFT OUTER JOIN VPCanvasSettingsTemplate ON VPCanvasSettingsTemplate.TemplateName = VPCanvasSettings.TemplateName
    WHERE VPUserName = @username AND TabNumber < @maxTabNumber
    ORDER BY TabNumber;
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetWorkCenterTabs] TO [public]
GO
