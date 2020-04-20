SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CJG
* Create date:  4/12/2011
* Modified Date: 
*
* Description:	Populates the CanvasGrid tables from the 
*		DisplayGrid tables
*
*	Inputs:
*	
*
*	Outputs:
*	
*	
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPCanvasGridFromDisplay]
	@NavigationID int, @PartId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @gridSettings TABLE (
		KeyID int
    )
    
    INSERT INTO @gridSettings(KeyID)	
	SELECT  VPDisplayGridSettings.KeyID	FROM VPDisplayGridSettings WHERE DisplayID = @NavigationID;
		
	DECLARE @DisplayGridSettingsId int
	SELECT TOP(1) @DisplayGridSettingsId = KeyID FROM @gridSettings
	WHILE @DisplayGridSettingsId IS NOT NULL
	BEGIN
		DECLARE @UserGridSettingsId INT
		
		INSERT INTO dbo.VPCanvasGridSettings
			        ( QueryName ,
			          GridLayout ,
			          Sort ,
			          MaximumNumberOfRows ,
			          ShowFilterBar ,
			          PartId,
			          QueryId,
			          GridType,
			          ShowConfiguration,
			          ShowTotals
			        )
			SELECT  VPDisplayGridSettings.QueryName,
					VPCanvasGridSettingsTemplate.GridLayout,					
					VPCanvasGridSettingsTemplate.Sort,
					VPDisplayGridSettings.MaximumNumberOfRows,
					'N', --ShowFilterBar
					@PartId,
					VPGridQueries.KeyID,
					VPDisplayGridSettings.GridType,
					'Y', --ShowConfiguration
				    'N'  --ShowTotals
				FROM VPDisplayGridSettings
				LEFT OUTER JOIN VPCanvasGridSettingsTemplate ON VPCanvasGridSettingsTemplate.QueryName = VPDisplayGridSettings.QueryName
				JOIN VPGridQueries ON VPGridQueries.QueryName = VPDisplayGridSettings.QueryName
				WHERE VPDisplayGridSettings.KeyID = @DisplayGridSettingsId
			
		SELECT @UserGridSettingsId = SCOPE_IDENTITY();
		
		INSERT INTO dbo.VPCanvasGridColumns
			        ( GridConfigurationId ,
			          Name ,
			          IsVisible,
			          Position 
			        )
			SELECT	@UserGridSettingsId,
					Name,
					IsVisible,
					Position
			FROM VPDisplayGridColumns
			WHERE GridConfigurationId = @DisplayGridSettingsId
			
			
		INSERT INTO dbo.VPCanvasGridParameters
			        ( GridConfigurationId ,
			          Name ,
			          SqlType ,
			          ParameterValue
			        )
			SELECT	@UserGridSettingsId,
					Name,
					SqlType,
					ParameterValue
			FROM VPDisplayGridParameters
			WHERE GridConfigurationId = @DisplayGridSettingsId
		
		-- Iterate
		DELETE FROM @gridSettings WHERE KeyID = @DisplayGridSettingsId
		SET @DisplayGridSettingsId = NULL
		SELECT TOP(1) @DisplayGridSettingsId = KeyID FROM @gridSettings
	END
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVPCanvasGridFromDisplay] TO [public]
GO
