SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: CJG 02/21/2011
* MODIFIED BY: CC 06/23/2011 - Add username & company to enforce security
*			   HH 11/27/2012 - added RefreshInterval to selection
*
*
*
*
* Usage: Loads the template groups from VPCanvasTemplateGroup
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
CREATE PROCEDURE [dbo].[vspVPGetCanvasTemplateGroups]
(@Co bCompany, @username bVPUserName)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableTemplates TABLE (TemplateName varchar(20));
	
	INSERT INTO @AvailableTemplates EXEC dbo.vspVPGetAvailableTemplates @Co = @Co, @username = @username;
		
	SELECT VPCanvasTemplateGroup.KeyID, VPCanvasTemplateGroup.Description, VPCanvasSettingsTemplate.TemplateName, VPCanvasSettingsTemplate.RefreshInterval
	FROM VPCanvasSettingsTemplate
	INNER JOIN VPCanvasTemplateGroup ON VPCanvasTemplateGroup.KeyID = VPCanvasSettingsTemplate.GroupID
	INNER JOIN @AvailableTemplates ON dbo.VPCanvasSettingsTemplate.TemplateName = [@AvailableTemplates].TemplateName
	ORDER BY VPCanvasTemplateGroup.KeyID
    
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasTemplateGroups] TO [public]
GO
