SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/15/2010
* Description:	Saves grid settings for My Viewpoint
*
* Modification:	TK-14628 HH 5/2/2012 Added VPCanvasGridColumns.FilterValue 	
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridColumn]
	-- Add the parameters for the stored procedure here
	@ConfigurationId INT,
	@Name VARCHAR(128) ,
    @IsVisible bYN,
    @Position INT,
	@FilterValue VARCHAR(128)	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS (	SELECT 1
				FROM VPCanvasGridColumns
				WHERE GridConfigurationId = @ConfigurationId AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridColumns
			SET IsVisible = @IsVisible, Position = @Position, FilterValue = @FilterValue
			WHERE GridConfigurationId = @ConfigurationId AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridColumns
			        ( GridConfigurationId ,
			          Name ,
			          IsVisible,
			          Position,
			          FilterValue 
			        )
			VALUES  ( 
		 			  @ConfigurationId ,
					  @Name ,
					  @IsVisible,
					  @Position,
					  @FilterValue
			        );			
		END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridColumn] TO [public]
GO
