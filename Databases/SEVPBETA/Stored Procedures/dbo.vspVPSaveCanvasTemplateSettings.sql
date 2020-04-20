SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		CC
* Create date:  8/25/2008
* Description:	Saves 'My Viewpoint' Canvas template layout settings
*
*	Inputs:
*	@TemplateName		The template to save settings for
*	@TableLayout		The serialized tablelayout settings
*	@NumberOfRows		The number of rows in the table
*	@NumberOfColumns	The number of columns in the table
*	@RefreshInterval	How frequently to refresh the parts on the Canvas
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveCanvasTemplateSettings]
	-- Add the parameters for the stored procedure here
	@TemplateName VARCHAR(20) = NULL,
	@TableLayout VARBINARY(MAX) = NULL,
	@NumberOfRows int = NULL,
	@NumberOfColumns int = NULL,
	@RefreshInterval int = NULL
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @IsStandard bYN
	IF SUSER_SNAME() = 'viewpointcs'
		SET @IsStandard = 'Y'
	ELSE
		SET @IsStandard = 'N'

	IF EXISTS(SELECT TOP 1 1 FROM VPCanvasSettingsTemplate WHERE TemplateName = @TemplateName)
		UPDATE VPCanvasSettingsTemplate 
			SET TableLayout = @TableLayout, 
				NumberOfRows = @NumberOfRows,
				NumberOfColumns = @NumberOfColumns,
				RefreshInterval = @RefreshInterval 
			WHERE TemplateName = @TemplateName
	ELSE
		INSERT INTO VPCanvasSettingsTemplate (TemplateName, IsStandard, TableLayout, NumberOfRows, NumberOfColumns, RefreshInterval) 
				VALUES (@TemplateName, @IsStandard, @TableLayout, @NumberOfRows, @NumberOfColumns, @RefreshInterval)

END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveCanvasTemplateSettings] TO [public]
GO
