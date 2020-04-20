SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPSetSelectedTemplate]
/***********************************************************
* CREATED BY: CC 09/10/2008
* MODIFIED BY: CJG 02/21/2011 - TK-01733 Updated to support Multiple tabs
*			   CJG 03/17/2011 - TK-02696 Added ShowConfiguration to VPCanvasGridSettingsTemplate
*			   CJG 03/30/2011 - TK-03301 Added @DisplayTabKeyID and integrated the VPDisplayTreeItems table
*			   CJG 04/08/2011 - TK-03983 Added Item, ItemType, IsCustom to VPDisplayTreeItems
*			   CJG 04/12/2011 - TK-03983 Added Code for creating Custom Queries setup by Admin
*			   HH 11/28/2012 - B-11081 Added RefreshInterval  
*
* Usage: Updates the selected template for the user
*
* Input params:
*	@username
*	@TabNumber
*	@TemplateName
*	@TabName
*	@DisplayTabKeyID - KeyID from VPDisplayTabs
* Output params:
*	none
*
* Return code:
*	
************************************************************/

(@username bVPUserName, 
 @TabNumber INT,
 @TemplateName AS VARCHAR(50),
 @TabName AS VARCHAR(50) = 'My Viewpoint',
 @RefreshInterval AS INT = NULL,
 @DisplayTabKeyID AS INT = -1)

AS
BEGIN
   SET NOCOUNT ON
   
    DECLARE @showMyViewpintTab As bYN	
	select @showMyViewpintTab = ShowMyViewpoint from DDVS
   
    -- Since multiple tabs are allowed, set the DDUP SelectedTemplate only for the
    -- First tab (My Viewpoint) if its shown.
    IF @showMyViewpintTab = 'Y' AND @TabNumber = 1
    BEGIN
		UPDATE DDUP SET SelectedTemplate = @TemplateName WHERE VPUserName = @username;
	END

	DELETE FROM VPCanvasSettings WHERE VPUserName = @username AND TabNumber = @TabNumber;

	INSERT INTO VPCanvasSettings (VPUserName, TabNumber, NumberOfRows, NumberOfColumns, RefreshInterval, TableLayout, TabName, TemplateName, GridLayout)
	SELECT @username, @TabNumber, NumberOfRows, NumberOfColumns, ISNULL(@RefreshInterval, RefreshInterval), TableLayout, @TabName, @TemplateName, GridLayout
	FROM VPCanvasSettingsTemplate
	WHERE TemplateName = @TemplateName;

	DECLARE @CanvasId INT;
	SELECT @CanvasId = SCOPE_IDENTITY();

	INSERT INTO VPPartSettings (CanvasId, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse)
	SELECT @CanvasId, PartName, ColumnNumber, RowNumber, Height, Width, ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse
	FROM VPPartSettingsTemplate
	WHERE TemplateName = @TemplateName;

	DECLARE @GridPartId TABLE
			(
				PartId int
			);

	INSERT INTO dbo.VPCanvasGridPartSettings( PartId, LastQuery)
	OUTPUT Inserted.PartId INTO @GridPartId (PartId)
	SELECT	VPPartSettings.KeyID, 
			VPCanvasGridPartSettingsTemplate.LastQuery
	FROM VPCanvasGridPartSettingsTemplate
	INNER JOIN VPPartSettingsTemplate ON VPPartSettingsTemplate.KeyID = VPCanvasGridPartSettingsTemplate.PartId
	INNER JOIN dbo.VPPartSettings ON VPPartSettingsTemplate.ColumnNumber = VPPartSettings.ColumnNumber AND VPPartSettingsTemplate.RowNumber = VPPartSettings.RowNumber AND dbo.VPPartSettings.CanvasId = @CanvasId;

	DECLARE @GridConfigurationIdMappings TABLE
			(
				TemplateConfigurationId INT,
				NewConfigurationId INT
			);
	
	INSERT INTO dbo.VPCanvasGridSettings
			( PartId ,
			  QueryName ,
			  GridLayout ,
			  Sort ,
			  MaximumNumberOfRows ,
			  ShowFilterBar ,
			  QueryId,
			  GridType,
			  ShowConfiguration
			)
	OUTPUT inserted.KeyID INTO @GridConfigurationIdMappings (NewConfigurationId)
	SELECT	VPPartSettings.KeyID, 
			VPCanvasGridSettingsTemplate.QueryName,
			VPCanvasGridSettingsTemplate.GridLayout,
			VPCanvasGridSettingsTemplate.Sort,
			VPCanvasGridSettingsTemplate.MaximumNumberOfRows,
			VPCanvasGridSettingsTemplate.ShowFilterBar,
			VPCanvasGridSettingsTemplate.QueryId,
			VPCanvasGridSettingsTemplate.GridType,
			VPCanvasGridSettingsTemplate.ShowConfiguration
	FROM VPCanvasGridSettingsTemplate
	INNER JOIN VPPartSettingsTemplate ON VPPartSettingsTemplate.KeyID = VPCanvasGridSettingsTemplate.PartId
	INNER JOIN dbo.VPPartSettings ON VPPartSettingsTemplate.ColumnNumber = VPPartSettings.ColumnNumber AND VPPartSettingsTemplate.RowNumber = VPPartSettings.RowNumber AND dbo.VPPartSettings.CanvasId = @CanvasId;

	UPDATE @GridConfigurationIdMappings
	SET TemplateConfigurationId = VPCanvasGridSettings.KeyID
	FROM VPCanvasGridSettings
	INNER JOIN @GridConfigurationIdMappings ON NewConfigurationId = KeyID
	INNER JOIN VPCanvasGridSettingsTemplate 
		ON	VPCanvasGridSettings.QueryName = VPCanvasGridSettingsTemplate.QueryName;
			
	INSERT INTO dbo.VPCanvasGridColumns
	        ( GridConfigurationId ,
	          Name ,
	          IsVisible ,
	          Position
	        )
	SELECT	mappings.NewConfigurationId,
			VPCanvasGridColumnsTemplate.Name,
			VPCanvasGridColumnsTemplate.IsVisible,
			VPCanvasGridColumnsTemplate.Position
	FROM VPCanvasGridColumnsTemplate
	INNER JOIN @GridConfigurationIdMappings AS mappings ON mappings.TemplateConfigurationId = GridConfigurationId;
	
	INSERT INTO dbo.VPCanvasGridGroupedColumns
	        ( GridConfigurationId ,
	          Name ,
	          ColumnOrder
	        )
	SELECT	mappings.NewConfigurationId,
			VPCanvasGridGroupedColumnsTemplate.Name,
			VPCanvasGridGroupedColumnsTemplate.ColumnOrder
	FROM	dbo.VPCanvasGridGroupedColumnsTemplate
	INNER JOIN @GridConfigurationIdMappings AS mappings ON mappings.TemplateConfigurationId = GridConfigurationId;
	
	INSERT INTO dbo.VPCanvasGridParameters
	        ( GridConfigurationId ,
	          Name ,
	          SqlType ,
	          ParameterValue
	        )
	SELECT	mappings.NewConfigurationId,
			VPCanvasGridParametersTemplate.Name,
			VPCanvasGridParametersTemplate.SqlType,
			VPCanvasGridParametersTemplate.ParameterValue
	FROM dbo.VPCanvasGridParametersTemplate
	INNER JOIN @GridConfigurationIdMappings AS mappings ON mappings.TemplateConfigurationId = GridConfigurationId;
	
	DECLARE @NavigationID int	
	SELECT @NavigationID = NavigationID FROM VPDisplayTabs WHERE KeyID = @DisplayTabKeyID
	
	DECLARE @TreeUserIds TABLE
	(
		UserId INT
	);
	
	WITH MaxTreeID(value)
	AS
	(
		SELECT ISNULL(MAX(KeyID), 0)
		FROM dbo.VPCanvasTreeItems
	)
	INSERT INTO dbo.VPCanvasTreeItems
	        ( KeyID ,
			  ItemType ,
	          Item ,
	          ParentId ,
	          ItemOrder ,
	          CanvasId ,
	          ItemTitle ,
	          Expanded ,
	          ShowItem ,
	          IsCustom
	        )
	OUTPUT Inserted.KeyID INTO @TreeUserIds(UserId)
	SELECT  MaxTreeID.value + ROW_NUMBER() OVER (ORDER BY VPCanvasTreeItemsTemplate.KeyID),
	        ISNULL(VPDisplayTreeItems.ItemType, VPCanvasTreeItemsTemplate.ItemType) ,
	        ISNULL(VPDisplayTreeItems.Item, VPCanvasTreeItemsTemplate.Item) ,
	        ISNULL(DisplayParent.TreeItemTemplateID, VPCanvasTreeItemsTemplate.ParentId) ,
	        ISNULL(VPDisplayTreeItems.ItemOrder, VPCanvasTreeItemsTemplate.ItemOrder) ,	        
	        @CanvasId ,
	        ISNULL(VPDisplayTreeItems.ItemTitle, VPCanvasTreeItemsTemplate.ItemTitle) ,
	        Expanded ,
	        ISNULL(VPDisplayTreeItems.ShowItem, VPCanvasTreeItemsTemplate.ShowItem),
	        ISNULL(VPDisplayTreeItems.IsCustom, 'N')
	FROM VPCanvasTreeItemsTemplate
	CROSS JOIN MaxTreeID	
	LEFT OUTER JOIN VPDisplayTreeItems
		ON VPDisplayTreeItems.TreeItemTemplateID = VPCanvasTreeItemsTemplate.KeyID
		AND VPDisplayTreeItems.TabNavigationID = @NavigationID
	LEFT OUTER JOIN VPDisplayTreeItems AS DisplayParent ON DisplayParent.KeyID = VPDisplayTreeItems.ParentID
	WHERE TemplateName = @TemplateName;
	
	
	-- Get Any Custom Items added by Admin
	WITH MaxTreeID(value)
	AS
	(
		SELECT ISNULL(MAX(KeyID), 0)
		FROM dbo.VPCanvasTreeItems
	)
	INSERT INTO dbo.VPCanvasTreeItems
	        ( KeyID ,
			  ItemType ,
	          Item ,
	          ParentId ,
	          ItemOrder ,
	          CanvasId ,
	          ItemTitle ,
	          Expanded ,
	          ShowItem ,
	          IsCustom
	        )
	OUTPUT Inserted.KeyID INTO @TreeUserIds(UserId)
	SELECT  MaxTreeID.value + ROW_NUMBER() OVER (ORDER BY VPCanvasTreeItemsTemplate.KeyID),
		VPDisplayTreeItems.ItemType ,
		VPDisplayTreeItems.Item ,
		ISNULL(DisplayParent.TreeItemTemplateID, VPCanvasTreeItemsTemplate.ParentId),
		VPDisplayTreeItems.ItemOrder,
		@CanvasId ,
		VPDisplayTreeItems.ItemTitle,
		'N', --Expanded
		VPDisplayTreeItems.ShowItem,
		'Y'  --IsCustom
	FROM VPDisplayTreeItems
		CROSS JOIN MaxTreeID
		LEFT OUTER JOIN VPDisplayTreeItems AS DisplayParent ON DisplayParent.KeyID = VPDisplayTreeItems.ParentID
		LEFT OUTER JOIN VPCanvasTreeItemsTemplate ON VPCanvasTreeItemsTemplate.KeyID = DisplayParent.TreeItemTemplateID
	WHERE VPDisplayTreeItems.TabNavigationID = @NavigationID
		AND VPDisplayTreeItems.IsCustom = 'Y'
	
	DECLARE @NumberOfRowsInserted INT,
			@LastUserId INT,
			@Offset INT;
	
	SELECT	@NumberOfRowsInserted = COUNT(*) ,
			@LastUserId = MAX(UserId) 
	FROM @TreeUserIds;
	
	SET @Offset = @LastUserId - @NumberOfRowsInserted;
	
	WITH TemplateUserIdMapping(TemplateId, UserId)
	AS
	(
		SELECT	KeyID ,
				ROW_NUMBER() OVER (ORDER BY KeyID) + @Offset
		FROM VPCanvasTreeItemsTemplate		
		WHERE TemplateName = @TemplateName
	)
	UPDATE VPCanvasTreeItems
	SET ParentId = UserId
	FROM VPCanvasTreeItems
	INNER JOIN TemplateUserIdMapping ON ParentId = TemplateId;

	-- Add any custom queries defined by the Admin
	IF @NavigationID >= 0
	BEGIN
		DECLARE @PartId as int	
		SELECT DISTINCT @PartId = PartId FROM @GridPartId

		EXEC vspVPCanvasGridFromDisplay @NavigationID, @PartId
	END
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPSetSelectedTemplate] TO [public]
GO
