SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  4/6/2012
* Description:	Saves grid settings for User Queries
*				into VPCanvasGridColumnsUser
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridColumnUser]
	-- Add the parameters for the stored procedure here
	@QueryName VARCHAR(128) ,
	@CustomName VARCHAR(128) ,
	@Name VARCHAR(128) ,
    @IsVisible bYN,
    @Position INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @VPUserName bVPUserName
	SELECT @VPUserName = SUSER_SNAME()
	
	IF EXISTS (	SELECT 1
				FROM VPCanvasGridColumnsUser
				WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridColumnsUser
			SET IsVisible = @IsVisible, Position = @Position
			WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridColumnsUser
			        ( VPUserName ,
			          QueryName ,
			          CustomName ,
			          Name ,
			          IsVisible,
			          Position 
			        )
			VALUES  ( 
		 			  @VPUserName ,
		 			  @QueryName ,
		 			  @CustomName ,
					  @Name ,
					  @IsVisible,
					  @Position
			        );			
		END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridColumnUser] TO [public]
GO
