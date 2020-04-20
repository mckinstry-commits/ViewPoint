SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  7/23/2008
* Changed by:	CC - 06/24/2011 add block for templates the user has been denied access to
* Description:	Retrieves 'My Viewpoint' Canvas settings
*
*	Inputs:
*	@UserName	The VP username to retrieve settings for
*
*	Outputs:
*	1st result set - table layout for the canvas
*	2nd result set - part position information
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPLoadCanvasSettings]
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = NULL,
	@TabNumber INT = NULL,
	@Co bCompany = NULL
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @AvailableTemplates TABLE (TemplateName varchar(20));
	INSERT INTO @AvailableTemplates EXEC dbo.vspVPGetAvailableTemplates @Co = @Co, @username = @UserName;
	
	SELECT  VPCanvasSettings.NumberOfRows ,
	        VPCanvasSettings.NumberOfColumns ,
	        VPCanvasSettings.GridLayout ,
	        VPCanvasSettings.RefreshInterval ,
	        VPCanvasSettings.KeyID AS CanvasId ,
	        GroupID,
	        VPCanvasSettings.FilterConfigurationSettings
	FROM VPCanvasSettings 
	INNER JOIN @AvailableTemplates ON [@AvailableTemplates].TemplateName = dbo.VPCanvasSettings.TemplateName
	LEFT OUTER JOIN dbo.VPCanvasSettingsTemplate ON dbo.VPCanvasSettings.TemplateName = dbo.VPCanvasSettingsTemplate.TemplateName
	WHERE VPUserName = @UserName AND TabNumber = @TabNumber;

	SELECT  VPPartSettings.KeyID,
			PartName ,
	        ColumnNumber ,
	        RowNumber ,
	        Height ,
	        Width ,
	        ConfigurationSettings,
	        CollapseDirection,
	        ShowConfiguration,
	        CanCollapse,
			IsCollapsed	        
	FROM VPPartSettings 
	INNER JOIN dbo.VPCanvasSettings ON dbo.VPPartSettings.CanvasId = dbo.VPCanvasSettings.KeyID	
	INNER JOIN @AvailableTemplates ON [@AvailableTemplates].TemplateName = dbo.VPCanvasSettings.TemplateName
	WHERE dbo.VPCanvasSettings.VPUserName = @UserName AND dbo.VPCanvasSettings.TabNumber = @TabNumber;

END
GO
GRANT EXECUTE ON  [dbo].[vspVPLoadCanvasSettings] TO [public]
GO
