SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		HH
* Create date:  4/6/2012
* Description:	Saves grid settings for User Queries
*				into VPCanvasGridParametersUser
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridParametersUser]
	-- Add the parameters for the stored procedure here
	@QueryName VARCHAR(128),
	@CustomName VARCHAR(128),
	@Name VARCHAR(128) ,
    @SqlType INT,
    @ParameterValue VARCHAR(256)
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @VPUserName bVPUserName
	SELECT @VPUserName = SUSER_SNAME()
	
	IF EXISTS(	SELECT 1
				FROM dbo.VPCanvasGridParametersUser
				WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridParametersUser
			SET SqlType = @SqlType,
				ParameterValue = @ParameterValue
			WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridParametersUser
			        ( VPUserName ,
					  QueryName ,
					  CustomName ,
			          Name ,
			          SqlType ,
			          ParameterValue
			        )
			VALUES  (	@VPUserName ,
						@QueryName ,
						@CustomName ,
						@Name ,
						@SqlType ,
						@ParameterValue 
			        );
		END
END
GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridParametersUser] TO [public]
GO
