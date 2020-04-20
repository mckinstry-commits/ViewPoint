SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  7/28/2010
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
CREATE PROCEDURE [dbo].[vspVPSaveCanvasPartLayout]
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = NULL,
	@TabNumber INT = NULL,
	@PartName VARCHAR(100) = NULL,
	@ColumnNumber int = NULL,
	@RowNumber int = NULL,
	@Height int = NULL,
	@Width int = NULL,
	@IsCollapsed bYN = 'N'
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(	SELECT TOP 1 1 
				FROM VPPartSettings
				INNER JOIN dbo.VPCanvasSettings ON dbo.VPPartSettings.CanvasId = dbo.VPCanvasSettings.KeyID
				WHERE	VPCanvasSettings.VPUserName = @UserName AND 
						VPCanvasSettings.TabNumber = @TabNumber AND
						PartName = @PartName AND 
						RowNumber = @RowNumber AND 
						ColumnNumber = @ColumnNumber)
		UPDATE VPPartSettings 
			SET		ColumnNumber = @ColumnNumber,
					RowNumber = @RowNumber,
					Height = @Height,
					Width = @Width,
					IsCollapsed = @IsCollapsed
		FROM VPPartSettings
		INNER JOIN dbo.VPCanvasSettings ON dbo.VPPartSettings.CanvasId = dbo.VPCanvasSettings.KeyID
			WHERE	VPCanvasSettings.VPUserName = @UserName
					AND VPCanvasSettings.TabNumber = @TabNumber 
					AND PartName = @PartName
					AND RowNumber = @RowNumber 
					AND ColumnNumber = @ColumnNumber;
	ELSE
		INSERT INTO VPPartSettings (CanvasId, PartName, ColumnNumber, RowNumber, Height, Width, IsCollapsed) 
			SELECT KeyID, @PartName, @ColumnNumber, @RowNumber, @Height, @Width, @IsCollapsed
			FROM dbo.VPCanvasSettings
			WHERE VPUserName = @UserName AND TabNumber = @TabNumber;

END
GO
GRANT EXECUTE ON  [dbo].[vspVPSaveCanvasPartLayout] TO [public]
GO
