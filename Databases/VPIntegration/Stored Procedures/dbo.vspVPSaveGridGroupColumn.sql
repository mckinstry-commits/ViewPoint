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
CREATE PROCEDURE [dbo].[vspVPSaveGridGroupColumn]
	-- Add the parameters for the stored procedure here
	@ConfigurationId INT,
	@Name VARCHAR(128) ,
    @Order INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (	SELECT 1
				FROM dbo.VPCanvasGridGroupedColumns
				WHERE GridConfigurationId = @ConfigurationId AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridGroupedColumns
			SET ColumnOrder = @Order
			WHERE GridConfigurationId = @ConfigurationId AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridGroupedColumns
			        ( GridConfigurationId ,
			          Name ,			         
			          ColumnOrder
			        )
			VALUES  ( 
		 			  @ConfigurationId ,
					  @Name ,
					  @Order 
			        );			
		END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridGroupColumn] TO [public]
GO
