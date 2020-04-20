SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/25/2008
* Description:	Retrieves 'My Viewpoint' Canvas template settings
*
*	Inputs:
*	@TemplateName	The VP username to retrieve settings for
*
*	Outputs:
*	1st result set - table layout for the canvas
*	2nd result set - part position information
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPLoadCanvasTemplateSettings]
	-- Add the parameters for the stored procedure here
	@TemplateName VARCHAR(20) = NULL
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT NumberOfRows, NumberOfColumns, TableLayout, RefreshInterval  FROM VPCanvasSettingsTemplate WHERE TemplateName = @TemplateName;

	SELECT PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings FROM VPPartSettingsTemplate WHERE TemplateName = @TemplateName;

END


GO
GRANT EXECUTE ON  [dbo].[vspVPLoadCanvasTemplateSettings] TO [public]
GO
