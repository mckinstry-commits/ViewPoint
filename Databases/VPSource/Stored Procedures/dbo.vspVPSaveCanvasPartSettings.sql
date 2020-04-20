SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  7/23/2008
* Description:	Saves a 'My Viewpoint' Canvas Part position and size
*
*	Inputs:
*	@UserName		The VP username to save settings for
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
CREATE PROCEDURE [dbo].[vspVPSaveCanvasPartSettings]
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = NULL,
	@TabNumber INT = NULL,
	@PartName VARCHAR(100) = NULL,
	@ColumnNumber int = NULL,
	@RowNumber int = NULL,
	@PartConfiguration VARBINARY(MAX) = NULL
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		UPDATE VPPartSettings 
			SET		ConfigurationSettings = @PartConfiguration
		FROM dbo.VPPartSettings
		INNER JOIN dbo.VPCanvasSettings ON dbo.VPPartSettings.CanvasId = dbo.VPCanvasSettings.KeyID
			WHERE	VPCanvasSettings.VPUserName = @UserName
					AND VPCanvasSettings.TabNumber = @TabNumber
					AND PartName = @PartName
					AND RowNumber = @RowNumber 
					AND ColumnNumber = @ColumnNumber;
END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveCanvasPartSettings] TO [public]
GO
