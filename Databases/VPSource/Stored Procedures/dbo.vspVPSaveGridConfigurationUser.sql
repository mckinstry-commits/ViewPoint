SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  4/6/2012
* Modified Date: 
* Description:	Saves grid settings for User Queries
*				into VPCanvasGridSettingsUser
*	Inputs:
*	
*
*	Outputs:
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPSaveGridConfigurationUser]
	-- Add the parameters for the stored procedure here
	@QueryName VARCHAR(128) , 
	@CustomName VARCHAR(128),
    @GridLayout VARCHAR(MAX),
    @Sort VARCHAR(128),
    @MaximumNumberOfRows INT,
    @ShowFilterBar bYN,
    @QueryId INT,
    @ShowConfiguration bYN,
    @ShowTotals bYN = 'N'
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements. 
	SET NOCOUNT ON;
	
	DECLARE @VPUserName bVPUserName
	SELECT @VPUserName = SUSER_SNAME()
	
	IF EXISTS (	SELECT 1 
				FROM VPCanvasGridSettingsUser
				WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName)
		BEGIN
			UPDATE dbo.VPCanvasGridSettingsUser
			SET VPUserName = @VPUserName,
				QueryName = @QueryName,
				CustomName = @CustomName,
				GridLayout = @GridLayout ,
				Sort = @Sort,
				MaximumNumberOfRows = @MaximumNumberOfRows,
				ShowFilterBar = @ShowFilterBar,
				QueryId = @QueryId,
				ShowConfiguration = @ShowConfiguration,
				ShowTotals = @ShowTotals
			WHERE VPUserName = @VPUserName
				AND QueryName = @QueryName
				AND CustomName = @CustomName;
		END
	ELSE
		BEGIN
			INSERT INTO dbo.VPCanvasGridSettingsUser
			        ( VPUserName ,
					  QueryName ,
			          CustomName,
			          GridLayout ,
			          Sort ,
			          MaximumNumberOfRows ,
			          ShowFilterBar ,
			          QueryId,
			          ShowConfiguration,
			          ShowTotals
			        )
			VALUES  ( @VPUserName ,
					  @QueryName ,
			          @CustomName,
			          @GridLayout ,
			          @Sort ,
			          @MaximumNumberOfRows ,
			          @ShowFilterBar ,
			          @QueryId,
			          @ShowConfiguration,
			          @ShowTotals
			        );
		END	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPSaveGridConfigurationUser] TO [public]
GO
