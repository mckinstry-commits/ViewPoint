SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  4/6/2012
* Description:	Saves grid settings for User Queries
*				into VPCanvasGridGroupedColumnsUser
*	Inputs:
*	
*
*	Outputs:
*	
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridGroupColumnUser]
	-- Add the parameters for the stored procedure here
	@QueryName VARCHAR(128) ,
	@CustomName VARCHAR(128) ,
	@Name VARCHAR(128) ,
    @Order INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @VPUserName bVPUserName
	SELECT @VPUserName = SUSER_SNAME()
	
	IF EXISTS (	SELECT 1
				FROM dbo.VPCanvasGridGroupedColumnsUser
				WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name)
		BEGIN
			UPDATE VPCanvasGridGroupedColumnsUser
			SET ColumnOrder = @Order
			WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName
				AND Name = @Name;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridGroupedColumnsUser
			        ( VPUserName ,
			          QueryName ,
			          CustomName ,
			          Name ,			         
			          ColumnOrder
			        )
			VALUES  ( 
		 			  @VPUserName ,
		 			  @QueryName ,
		 			  @CustomName ,
					  @Name ,
					  @Order 
			        );			
		END
END


GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridGroupColumnUser] TO [public]
GO
