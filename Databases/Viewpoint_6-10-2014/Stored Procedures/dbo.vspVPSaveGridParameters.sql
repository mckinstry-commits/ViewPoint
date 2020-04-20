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
CREATE PROCEDURE [dbo].[vspVPSaveGridParameters]
	-- Add the parameters for the stored procedure here
	@ConfigurationId INT,
	@Name VARCHAR(128) ,
    @SqlType INT,
    @ParameterValue VARCHAR(256)
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(	SELECT 1
				FROM dbo.VPCanvasGridParameters
				WHERE GridConfigurationId = @ConfigurationId AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridParameters
			SET SqlType = @SqlType,
				ParameterValue = @ParameterValue
			WHERE GridConfigurationId = @ConfigurationId AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridParameters
			        ( GridConfigurationId ,
			          Name ,
			          SqlType ,
			          ParameterValue
			        )
			VALUES  (	@ConfigurationId ,
						@Name ,
						@SqlType ,
						@ParameterValue 
			        );
		END
END
GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridParameters] TO [public]
GO
