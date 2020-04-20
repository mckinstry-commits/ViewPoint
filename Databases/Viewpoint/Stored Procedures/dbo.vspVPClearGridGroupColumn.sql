SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/15/2010
* Description:	Saves grid settings for My Viewpoint
*
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPClearGridGroupColumn]
	-- Add the parameters for the stored procedure here
	@ConfigurationId INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DELETE FROM dbo.VPCanvasGridGroupedColumns
	WHERE GridConfigurationId = @ConfigurationId;
END
GO
GRANT EXECUTE ON  [dbo].[vspVPClearGridGroupColumn] TO [public]
GO
