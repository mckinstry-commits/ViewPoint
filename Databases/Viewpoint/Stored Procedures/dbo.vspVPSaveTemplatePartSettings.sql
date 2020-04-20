SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/25/2008
* Description:	Saves a 'My Viewpoint' Canvas Part position and size
*
*	Inputs:
*	@TemplateName	The Template to save settings for
*	@PartName		The name of the part
*	@ColumnNumber	The column number the part has on the canvas
*	@RowNumber		The row number the part has on the canvas
*	@Height			The number of rows the part occupies
*	@Width			The number of columns the part occupies
*	@PartConfiguration	Serialized part settings
*
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveTemplatePartSettings]
	-- Add the parameters for the stored procedure here
	@TemplateName VARCHAR(20) = NULL,
	@PartName VARCHAR(100) = NULL,
	@ColumnNumber int = NULL,
	@RowNumber int = NULL,
	@Height int = NULL,
	@Width int = NULL,
	@PartConfiguration VARBINARY(MAX) = NULL
	  
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

	IF EXISTS(SELECT TOP 1 1 FROM VPPartSettingsTemplate WHERE TemplateName = @TemplateName AND PartName = @PartName AND RowNumber = @RowNumber AND ColumnNumber = @ColumnNumber)
		UPDATE VPPartSettingsTemplate 
			SET		ColumnNumber = @ColumnNumber,
					RowNumber = @RowNumber,
					Height = @Height,
					Width = @Width,
					ConfigurationSettings = @PartConfiguration
			WHERE	TemplateName = @TemplateName
					AND PartName = @PartName
					AND RowNumber = @RowNumber 
					AND ColumnNumber = @ColumnNumber
	ELSE
		INSERT INTO VPPartSettingsTemplate (TemplateName, IsStandard, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings) 
			VALUES (@TemplateName, @IsStandard, @PartName, @ColumnNumber, @RowNumber, @Height, @Width, @PartConfiguration)

END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveTemplatePartSettings] TO [public]
GO
