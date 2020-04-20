SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/15/2010
* Description:	Retrieves grid settings for My Viewpoint
*
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetGridPartSettings]
	-- Add the parameters for the stored procedure here
	@PartId INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT	VPCanvasGridSettings.KeyID, 
			VPCanvasGridSettings.GridType
	FROM dbo.VPCanvasGridPartSettings
	INNER JOIN dbo.VPCanvasGridSettings ON dbo.VPCanvasGridPartSettings.PartId = dbo.VPCanvasGridSettings.PartId AND LastQuery = QueryName
	WHERE VPCanvasGridPartSettings.PartId = @PartId;

END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridPartSettings] TO [public]
GO
