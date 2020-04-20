SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************
* Author:		CJG
* Create date:  04/11/2011
* Description:	Mirrors vspVPSaveGridParameters for the admin
*
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridParametersAdmin]
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
				FROM dbo.VPDisplayGridParameters
				WHERE GridConfigurationId = @ConfigurationId AND Name = @Name)
		BEGIN
			UPDATE VPDisplayGridParameters
			SET SqlType = @SqlType,
				ParameterValue = @ParameterValue
			WHERE GridConfigurationId = @ConfigurationId AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPDisplayGridParameters
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
GRANT EXECUTE ON  [dbo].[vspVPSaveGridParametersAdmin] TO [public]
GO
