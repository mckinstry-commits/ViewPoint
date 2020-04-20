SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************************************
* Author:		CC
* Create date:  8/15/2010
* Modification:	4/6/2012	HH TK-13724 Added @CustomName to identify 
*							Query in VPCanvasGridSettings
*				5/10/2012	HH TK-14882 Replaced @CustomName with @Seq
*	
* Description:	Retrieves grid settings for My Viewpoint
*
*	Inputs:
*	
*
*	Outputs:
*	
*
**********************************************************************/
CREATE PROCEDURE [dbo].[vspVPGetGridConfigurationByName]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@QueryName VARCHAR(128),
	@Seq INT,
	@ConfigurationId INT OUTPUT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @GridType INT;
	SET @GridType = 0;
	
	SELECT	@ConfigurationId = VPCanvasGridSettings.KeyID,
	@GridType = VPCanvasGridSettings.GridType
	FROM dbo.VPCanvasGridSettings
	LEFT OUTER JOIN VPCanvasGridPartSettings ON dbo.VPCanvasGridSettings.PartId = dbo.VPCanvasGridPartSettings.PartId
	WHERE VPCanvasGridSettings.PartId = @PartId AND QueryName = @QueryName AND dbo.VPCanvasGridSettings.Seq = @Seq

	
	EXEC dbo.vspVPGetGridConfiguration	@PartId = @PartId, 
										@ConfigurationId = @ConfigurationId,
										@GridType = @GridType;
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridConfigurationByName] TO [public]
GO
