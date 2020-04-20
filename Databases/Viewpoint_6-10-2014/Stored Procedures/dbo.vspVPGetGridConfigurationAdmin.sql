SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		CJG
* Create date:  4/11/2011
* MODIFIED By : HH 10/29/2012 TK-18922 added dummy columns
*							to match with non-admin execution
*
* Description:	Mirrors vspVPGetGridConfiguration for the Admin
*
*	Inputs:
*	
*
*	Outputs:
*	
*	
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetGridConfigurationAdmin]
	-- Add the parameters for the stored procedure here
	@PartId INT,
	@ConfigurationId INT,
	@GridType INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- @ConfigurationId is actually the DisplayTreeItem KeyID
	-- convert it to the TreeItems DisplayGridSettings
	SELECT @ConfigurationId = GridConfigurationID
	FROM VPDisplayTreeItems
	WHERE KeyID = @ConfigurationId

	SELECT	Name ,
			IsVisible,
			Position,
			'' AS FilterValue
	FROM dbo.VPDisplayGridColumns
	WHERE GridConfigurationId = @ConfigurationId;
	
	SELECT	VPCanvasGridSettingsTemplate.GridLayout ,
	        VPCanvasGridSettingsTemplate.Sort ,
	        ISNULL(VPDisplayGridSettings.MaximumNumberOfRows, VPCanvasGridSettingsTemplate.MaximumNumberOfRows) AS MaximumNumberOfRows,
	        VPCanvasGridSettingsTemplate.ShowFilterBar,
	        VPDisplayGridSettings.QueryName,
	        VPGridQueries.KeyID AS QueryId,
	        ISNULL(VPDisplayGridSettings.GridType, VPCanvasGridSettingsTemplate.GridType) AS GridType,
	        VPCanvasGridSettingsTemplate.ShowConfiguration,
	        'N'  As ShowTotals,
	        (SELECT ItemTitle FROM VPDisplayTreeItems WHERE GridConfigurationID = @ConfigurationId) AS CustomName,
	        0 As Seq,
	        0 As SelectedRow
	FROM VPDisplayGridSettings
	LEFT OUTER JOIN VPCanvasGridSettingsTemplate ON VPCanvasGridSettingsTemplate.QueryName = VPDisplayGridSettings.QueryName
	JOIN VPGridQueries ON VPGridQueries.QueryName = VPDisplayGridSettings.QueryName
	WHERE VPDisplayGridSettings.KeyID = @ConfigurationId;
	
	DECLARE @emptyTable TABLE (Name varchar(128))
	
	-- RETURN NOTHING
	SELECT Name FROM @emptyTable
	
	SELECT	Name ,
	        SqlType ,
	        ParameterValue
	FROM dbo.VPDisplayGridParameters
	WHERE GridConfigurationId = @ConfigurationId;
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridConfigurationAdmin] TO [public]
GO
