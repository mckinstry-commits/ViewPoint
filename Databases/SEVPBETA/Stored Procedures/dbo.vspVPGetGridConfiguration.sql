SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  8/15/2010
* Modified Date: ChrisG 3/18/2011 TK-02696 - Added ShowConfiguration
*				 HH 4/5/2012 TK-13724 - Added CustomName
*				 HH 5/2/2012 TK-14628 - Added VPCanvasGridColumns.FilterValue in return dataset
*				 HH 5/2/2012 TK-14882 - Added Sequence to VPCanvasGridSettings selection
*				 HH 6/5/2012 TK-15193 - Added SelectedRow to VPCanvasGridSettings selection
*
* Description:	Retrieves grid settings for My Viewpoint
*
*	Inputs:
*	
*
*	Outputs:
*	
*	Updated 2/15/2011 Added Position column for CanvasGridColumns data retrival.
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetGridConfiguration]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@ConfigurationId INT,
	@GridType INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @GridType = 1
		BEGIN		
			--Remove any columns that have been removed from DDFIShared	
			DECLARE @FormName VARCHAR(30);
			SELECT @FormName = QueryName
			FROM VPCanvasGridSettings 
			WHERE VPCanvasGridSettings.KeyID = @ConfigurationId;
			
			DELETE VPCanvasGridColumns
			FROM dbo.VPCanvasGridColumns
			LEFT OUTER JOIN vfVPGetColumnsForMyViewpoint(@FormName) AS DDColumns ON DDColumns.ColumnName = VPCanvasGridColumns.Name
			WHERE	DDColumns.Name IS NULL AND
					GridConfigurationId = @ConfigurationId;
			
			DELETE VPCanvasGridGroupedColumns
			FROM dbo.VPCanvasGridGroupedColumns
			LEFT OUTER JOIN vfVPGetColumnsForMyViewpoint(@FormName) AS DDColumns ON DDColumns.Name = VPCanvasGridGroupedColumns.Name
			WHERE	DDColumns.Name IS NULL AND
			GridConfigurationId = @ConfigurationId;
		
			SELECT 'FormName' AS Name , 'N' AS IsVisible, -1 as Position, '' AS FilterValue UNION 
			SELECT 'KEYID' AS Name , 'N' AS IsVisible, -2 as Position, '' AS FilterValue UNION 
			SELECT	Name ,
					IsVisible,
					Position,
					FilterValue 
			FROM dbo.VPCanvasGridColumns
			WHERE GridConfigurationId = @ConfigurationId;
		END
	ELSE
		BEGIN
			SELECT	Name ,
					IsVisible,
					Position,
					FilterValue  
			FROM dbo.VPCanvasGridColumns
			WHERE GridConfigurationId = @ConfigurationId;
		END
	
	SELECT	GridLayout ,
	        Sort ,
	        MaximumNumberOfRows ,
	        ShowFilterBar,
	        QueryName,
	        QueryId,
	        VPCanvasGridSettings.GridType,
	        VPCanvasGridSettings.ShowConfiguration,
	        ShowTotals,
	        VPCanvasGridSettings.CustomName,
	        VPCanvasGridSettings.Seq,
	        VPCanvasGridSettings.SelectedRow
	FROM VPCanvasGridSettings
	LEFT OUTER JOIN dbo.VPCanvasGridPartSettings ON VPCanvasGridPartSettings.PartId = @PartId	
	WHERE	VPCanvasGridSettings.PartId = @PartId AND VPCanvasGridSettings.KeyID = @ConfigurationId;
	
	SELECT Name
	FROM dbo.VPCanvasGridGroupedColumns
	WHERE GridConfigurationId = @ConfigurationId;
	
	SELECT	Name ,
	        SqlType ,
	        ParameterValue
	FROM dbo.VPCanvasGridParameters
	WHERE GridConfigurationId = @ConfigurationId;
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridConfiguration] TO [public]
GO
