SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPCloneUserWorkCentersToGroup]
/***********************************************************
* CREATED BY: GPT 10/31/2011
* MODIFIED BY: 

* Usage: This procedure clones an existing user's work center configuration 
*		 to all users in a designated security group. Note this procedure skips the
*		 clone process for a target user if they already have atleast one work center 
*		 configured.
*
* Input params:
*	@SourceUser
*	@SecurityGroupID
*
* Output params:
*	none
*
* Return code:
*	
************************************************************/

(@SourceUser bVPUserName, 
 @SecurityGroupID int)
AS
BEGIN
   SET NOCOUNT ON
   
   DECLARE @targetUser bVPUserName
   
   DECLARE @Users TABLE (UserName bVPUserName);
   DECLARE @CanvasMappings TABLE ( SourceID int, CloneID int);
   DECLARE @PartMappings TABLE   ( SourceID int, CloneID int);
   DECLARE @TreeMappings TABLE	( SourceID int, CloneID int);
   DECLARE @GridConfigurationMappings TABLE ( SourceID int, CloneID int);
   
   DECLARE @error_text VarChar(128)
     
   /* Does @SourceUser have Work Centers configured */
	IF NOT EXISTS ( SELECT TOP 1 1 FROM [dbo].[vVPCanvasSettings] WHERE VPUserName = @SourceUser)
		BEGIN
			SET @error_text = '@SourceUser does not have an work center settings to clone.'
			GOTO error_text
		END
		
   /* Is the @SecurityGroupID a valid security group */
   IF NOT EXISTS ( SELECT TOP 1 1 FROM [dbo].[vDDSU] WHERE SecurityGroup = @SecurityGroupID)
		BEGIN
			SET @error_text = '@SecurityGroupID is not a valid security group.'
			GOTO error_text
		END
   
   /* Get list of users in security group */
   INSERT INTO @Users (UserName)
   SELECT VPUserName FROM [dbo].[vDDSU] WHERE SecurityGroup = @SecurityGroupID

   /* Loop through each user, performing the clone of the setup */  
   WHILE EXISTS (SELECT TOP 1 * FROM @Users)
   BEGIN
	   
		SET @targetUser = (SELECT TOP 1 UserName FROM @Users)

		/* Make sure the user does not have existing canvas items */ 
		IF EXISTS ( SELECT TOP 1 * FROM [dbo].[vVPCanvasSettings] WHERE VPUserName = @targetUser)
		BEGIN
		GOTO next_user
		END

		/* VPCanvasSettings: clone the canvas items for the users */

		INSERT INTO vVPCanvasSettings (VPUserName, TabNumber, NumberOfRows, NumberOfColumns, RefreshInterval, 
						  TableLayout, TabName, TemplateName, GridLayout)
		OUTPUT inserted.KeyID INTO @CanvasMappings ( CloneID )
		SELECT @targetUser, 
			TabNumber, 
			NumberOfRows, 
			NumberOfColumns, 
			RefreshInterval, 
			TableLayout, 
			TabName, 
			TemplateName, 
			GridLayout
		FROM [dbo].[VPCanvasSettings] as settings
		WHERE VPUserName = @SourceUser;

		/* Capture mapping of new CanvasID to old CanvasID */
		UPDATE @CanvasMappings
			SET SourceID = sourceCanvas.KeyID
		FROM @CanvasMappings as mapping
		INNER JOIN [dbo].[VPCanvasSettings] as clonedCanvas ON (clonedCanvas.KeyID = mapping.CloneID) 
		INNER JOIN [dbo].[VPCanvasSettings] as sourceCanvas ON (sourceCanvas.[TabNumber] = clonedCanvas.TabNumber) 
		WHERE sourceCanvas.VPUserName = @SourceUser


		/* VPPartSettings: clone the parts for each canvas item */
		INSERT INTO VPPartSettings (CanvasId, PartName, ColumnNumber, RowNumber, Height, Width, 
					   ConfigurationSettings, CollapseDirection, ShowConfiguration, CanCollapse)
		OUTPUT inserted.KeyID INTO @PartMappings( CloneID )
		SELECT mappings.CloneID, 
			PartName, 
			ColumnNumber, 
			RowNumber, 
			Height, 
			Width, 
			ConfigurationSettings, 
			CollapseDirection, 
			ShowConfiguration, 
			CanCollapse
		FROM [dbo].[VPPartSettings] 
		INNER JOIN @CanvasMappings as mappings ON mappings.SourceID = CanvasId;

		/* Capture mapping of new PartID to old PartID*/
		UPDATE @PartMappings 
			SET SourceID = [sourceParts].KeyID
		FROM @PartMappings partMaps
		INNER JOIN [dbo].[VPPartSettings] as clonedParts ON (partMaps.CloneID =  clonedParts.KeyID)
		INNER JOIN @CanvasMappings as canvasMaps ON (canvasMaps.CloneID = clonedParts.CanvasId)
		INNER JOIN [dbo].[VPPartSettings] as sourceParts ON (canvasMaps.SourceID = sourceParts.CanvasId)
		WHERE clonedParts.ColumnNumber = sourceParts.ColumnNumber and clonedParts.RowNumber = sourceParts.RowNumber;



		/* VPCanvasTreeItems: clone the tree parts for each canvas item, if relevant */
		WITH MaxTreeID(value)
		AS
		(
			SELECT ISNULL(MAX(KeyID), 0)
			FROM dbo.VPCanvasTreeItems
		)
		INSERT INTO dbo.VPCanvasTreeItems ( KeyID, ItemType, Item, ParentId, ItemOrder, CanvasId, ItemTitle, 
							   Expanded, ShowItem, IsCustom)
		OUTPUT inserted.KeyID INTO @TreeMappings( CloneID )
		SELECT	MaxTreeID.value + ROW_NUMBER() OVER (ORDER BY VPCanvasTreeItems.KeyID),
			VPCanvasTreeItems.ItemType ,
			VPCanvasTreeItems.Item ,
			VPCanvasTreeItems.ParentId ,
			VPCanvasTreeItems.ItemOrder ,	        
			mappings.CloneID ,
			VPCanvasTreeItems.ItemTitle,
			VPCanvasTreeItems.Expanded ,
			VPCanvasTreeItems.ShowItem,
			VPCanvasTreeItems.IsCustom
		FROM [dbo].[VPCanvasTreeItems]
		CROSS JOIN MaxTreeID	
		INNER JOIN @CanvasMappings as mappings ON mappings.SourceID = CanvasId;


		/* Capture mapping of new TreeID to old TreeID*/
		WITH MinTreeKeyIDs(SourceID, CloneID, SourceMinKeyID, CloneMinKeyID)
		AS
		(
			SELECT mappings.SourceID, 
				mappings.CloneID, 
				MIN(sourceTrees.KeyID),
				MIN(cloneTrees.KeyID)
			FROM @CanvasMappings mappings
			INNER JOIN	[VPCanvasTreeItems]	as cloneTrees ON cloneTrees.CanvasId = mappings.CloneID
			INNER JOIN	[VPCanvasTreeItems]	as sourceTrees ON sourceTrees.CanvasId = mappings.SourceID
			Group By SourceID, CloneID
		) 
		UPDATE @TreeMappings 
			SET SourceID = [sourceTrees].KeyID
		FROM @TreeMappings treeMaps
		INNER JOIN [dbo].[VPCanvasTreeItems] as clonedTrees ON (treeMaps.CloneID =  clonedTrees.KeyID)
		INNER JOIN @CanvasMappings as canvasMaps ON (canvasMaps.CloneID = clonedTrees.CanvasId)
		INNER JOIN [dbo].[VPCanvasTreeItems] as sourceTrees ON (canvasMaps.SourceID = sourceTrees.CanvasId)
		INNER JOIN MinTreeKeyIDs minIDs ON (minIDs.SourceID = canvasMaps.SourceID AND minIDs.CloneID = canvasMaps.CloneID)
		WHERE ( sourceTrees.KeyID - minIDs.SourceMinKeyID ) = ( clonedTrees.KeyID - minIDs.CloneMinKeyID )

		/* Update ParentID based on mapping */
		UPDATE [dbo].[VPCanvasTreeItems] 
			SET ParentId = parentCloneMaps.CloneID
		FROM [dbo].[VPCanvasTreeItems] treeItems
		INNER JOIN @TreeMappings AS treeMaps ON (treeItems.KeyID = treeMaps.CloneID)
		INNER JOIN @TreeMappings as parentCloneMaps ON (treeItems.ParentId = parentCloneMaps.SourceID)



		/* VPCanvasGridPartSettings: clone the grid part setting for each grid part */
		INSERT INTO dbo.VPCanvasGridPartSettings( PartId, LastQuery)
		SELECT	mappings.CloneID, 
			VPCanvasGridPartSettings.LastQuery
		FROM [dbo].[VPCanvasGridPartSettings]
		INNER JOIN @PartMappings as mappings ON mappings.SourceID = VPCanvasGridPartSettings.PartId;

		/* VPCanvasGridSettings: clone the grid settings for each grid part */
		INSERT INTO dbo.VPCanvasGridSettings ( PartId , QueryName , GridLayout , Sort , MaximumNumberOfRows , 
								   ShowFilterBar , QueryId, GridType, ShowConfiguration )
		OUTPUT inserted.KeyID INTO @GridConfigurationMappings ( CloneID )
		SELECT	mappings.CloneID, 
			QueryName,
			GridLayout,
			Sort,
			MaximumNumberOfRows,
			ShowFilterBar,
			QueryId,
			GridType,
			ShowConfiguration
		FROM [dbo].[VPCanvasGridSettings]
		INNER JOIN @PartMappings as mappings ON mappings.SourceID = PartId;

		/* Capture mapping of old GridConfigID to new ID */
		UPDATE @GridConfigurationMappings 
			SET SourceID = [sourceConfigs].KeyID
		FROM @GridConfigurationMappings configMaps
		INNER JOIN [dbo].[VPCanvasGridSettings] as clonedConfigs ON (configMaps.CloneID =  clonedConfigs.KeyID)
		INNER JOIN @PartMappings as partMaps ON (partMaps.CloneID = clonedConfigs.PartId)
		INNER JOIN [dbo].[VPCanvasGridSettings] as sourceConfigs ON (partMaps.SourceID = sourceConfigs.PartId)
		WHERE clonedConfigs.QueryName = sourceConfigs.QueryName;



		/* VPCanvasGridParameters: clone the parameters for each GridSetting, if relevant */
		INSERT INTO dbo.VPCanvasGridParameters ( GridConfigurationId , Name , SqlType , ParameterValue )
		SELECT	mappings.CloneID,
			VPCanvasGridParameters.Name,
			VPCanvasGridParameters.SqlType,
			VPCanvasGridParameters.ParameterValue
		FROM [dbo].[VPCanvasGridParameters]
		INNER JOIN @GridConfigurationMappings AS mappings ON mappings.SourceID = GridConfigurationId;



		/* VPCanvasGridColumns: clone the parameters for each GridSetting, if relevant */
		INSERT INTO dbo.VPCanvasGridColumns ( GridConfigurationId , Name , IsVisible , Position )
		SELECT	mappings.CloneID,
			VPCanvasGridColumns.Name,
			VPCanvasGridColumns.IsVisible,
			VPCanvasGridColumns.Position
		FROM [dbo].[VPCanvasGridColumns]
		INNER JOIN @GridConfigurationMappings AS mappings ON mappings.SourceID = GridConfigurationId;



		/* VPCanvasGridGroupedColumns: clone the parameters for each GridSetting, if relevant */
		INSERT INTO dbo.VPCanvasGridGroupedColumns ( GridConfigurationId , Name , ColumnOrder )
		SELECT	mappings.CloneID,
			VPCanvasGridGroupedColumns.Name,
			VPCanvasGridGroupedColumns.ColumnOrder
		FROM [dbo].[VPCanvasGridGroupedColumns]
		INNER JOIN @GridConfigurationMappings AS mappings ON mappings.SourceID = GridConfigurationId;

next_user:
		
		/* Clean up mappings for next user */
		DELETE @CanvasMappings
		DELETE @PartMappings
		DELETE @GridConfigurationMappings
		DELETE @TreeMappings
		
		DELETE @Users WHERE UserName = @targetUser
	END
	
	RETURN 

error_text:
	
	RAISERROR (@error_text, 10, -1)
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVPCloneUserWorkCentersToGroup] TO [public]
GO
