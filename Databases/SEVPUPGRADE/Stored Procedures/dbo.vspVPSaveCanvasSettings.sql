SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  7/23/2008
* Description:	Saves 'My Viewpoint' Canvas layout settings
*
*	Inputs:
*	@UserName			The VP username to save settings for
*	@TableLayout		The serialized tablelayout settings
*	@NumberOfRows		The number of rows in the table
*	@NumberOfColumns	The number of columns in the table
*	@RefreshInterval	How frequently to refresh the parts on the Canvas
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveCanvasSettings]
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = null,
	@TabNumber INT = NULL,
	@GridLayout VARCHAR(MAX) = null,
	@NumberOfRows int = NULL,
	@NumberOfColumns int = NULL,
	@RefreshInterval int = NULL,
	@FilterConfiguration VARBINARY(MAX) = NULL
	
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT TOP 1 1 FROM VPCanvasSettings WHERE VPUserName = @UserName)
		UPDATE VPCanvasSettings 
			SET GridLayout = @GridLayout, 
				NumberOfRows = @NumberOfRows,
				NumberOfColumns = @NumberOfColumns,
				RefreshInterval = @RefreshInterval,
				FilterConfigurationSettings = @FilterConfiguration
			WHERE VPUserName = @UserName AND TabNumber = @TabNumber;
	ELSE
		INSERT INTO VPCanvasSettings (VPUserName, TabNumber, GridLayout, NumberOfRows, NumberOfColumns, RefreshInterval, FilterConfigurationSettings) 
				VALUES (@UserName, @TabNumber, @GridLayout, @NumberOfRows, @NumberOfColumns, @RefreshInterval, @FilterConfiguration);

END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveCanvasSettings] TO [public]
GO
