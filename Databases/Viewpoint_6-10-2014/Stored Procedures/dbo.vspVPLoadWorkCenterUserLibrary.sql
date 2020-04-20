SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		HH
* Create date:  3/14/2013 (PI day) -Mathematician: "Pi r squared" -Baker:" No! Pies are round, cakes are square!
* Description:	Load xml data from vVPWorkCenterUserLibrary into work center tables entries
*
*	Inputs:
*	@LibraryName	The library name to save for
*	@Owner			The owner of the library
*
*	Outputs:
*	None
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspVPLoadWorkCenterUserLibrary]
	-- Add the parameters for the stored procedure here
	@LibraryName VARCHAR(50) = NULL,
	@Owner VARCHAR(100) = NULL,
	@TabNumber INT,
	@TabName VARCHAR(50),
	@RefreshInterval INT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;

	DELETE FROM VPCanvasSettings WHERE VPUserName = SUSER_SNAME() AND TabNumber = @TabNumber;
	
	DECLARE @xml XML;
	
	SELECT @xml = WorkCenterInfo 
	FROM VPWorkCenterUserLibrary 
	WHERE LibraryName = @LibraryName AND [Owner] = @Owner AND PublicShare = CASE
																				WHEN @Owner <> SUSER_SNAME() THEN 'Y'
																				ELSE PublicShare
																			END;

	DECLARE @max INT, @i INT, @maxx INT, @ii INT, @maxxx INT, @iii INT;
	DECLARE @Mapping TABLE (SourcePartId INT, PartId INT, SourceGridConfigurationId INT, GridConfigurationId INT);
	
		
	--Processing VPCanvasSettings------------------------------------------------------
	DECLARE @CanvasId int 
	INSERT INTO VPCanvasSettings (VPUserName
								,NumberOfRows
								,NumberOfColumns
								,RefreshInterval
								,TableLayout
								,GridLayout
								,TabNumber
								,TabName
								,TemplateName
								,FilterConfigurationSettings)
	SELECT		SUSER_SNAME()
				,x.value('NumberOfRows[1]', 'int')
				,x.value('NumberOfColumns[1]', 'int')
				,@RefreshInterval
				,x.value('TableLayout[1]', 'varbinary(max)')
				,x.value('GridLayout[1]', 'varchar(max)')
				,@TabNumber
				,@TabName
				,x.value('TemplateName[1]', 'varchar(20)')
				,x.value('FilterConfigurationSettings[1]', 'varbinary(max)')
	FROM @xml.nodes('/root/VPCanvasSettings/row')e(x)
	SET @CanvasId = Scope_Identity();
		
	
	--Processing VPCanvasTreeItems------------------------------------------------------
	WITH cteVPCanvasTreeItems AS
	(
		SELECT	x.value('ItemType[1]', 'int') AS ItemType
				,x.value('ItemSeq[1]', 'int') AS ItemSeq
				,x.value('Item[1]', 'varchar(2048)') AS Item
				,x.value('ParentId[1]', 'int') AS ParentId
				,x.value('ItemOrder[1]', 'int') AS ItemOrder
				,@CanvasId AS CanvasId
				,x.value('ItemTitle[1]', 'varchar(128)') AS ItemTitle
				,x.value('Expanded[1]', 'bYN') AS Expanded
				,x.value('KeyID[1]', 'int') AS KeyID
				,x.value('ShowItem[1]', 'bYN') AS ShowItem
				,x.value('IsCustom[1]', 'bYN') AS IsCustom
				,(SELECT MAX(x.value('KeyID[1]', 'int')) FROM  @xml.nodes('/root/VPCanvasTreeItems/row')e(x)) + ROW_NUMBER() OVER (ORDER BY x.value('KeyID[1]', 'int')) AS NewKeyID
		FROM @xml.nodes('/root/VPCanvasTreeItems/row')e(x)
	)
	INSERT INTO VPCanvasTreeItems (ItemType
									,ItemSeq
									,Item
									,ParentId	--t2.NewKeyID
									,ItemOrder
									,CanvasId
									,ItemTitle
									,Expanded
									,KeyID		--t1.NewKeyID
									,ShowItem
									,IsCustom)
	SELECT t1.ItemType, t1.ItemSeq, t1.Item, t2.NewKeyID, t1.ItemOrder, t1.CanvasId, t1.ItemTitle, t1.Expanded, t1.NewKeyID, t1.ShowItem, t1.IsCustom
	FROM cteVPCanvasTreeItems t1
	LEFT JOIN cteVPCanvasTreeItems t2 ON t1.ParentId = t2.KeyID;


	-- Processing VPPartSettings------------------------------------------------------
	DECLARE @VPPartSettingsMapping TABLE(SourceKeyID int, KeyID int);

	INSERT INTO VPPartSettings (PartName
									,ColumnNumber
									,RowNumber
									,Height
									,Width
									,ConfigurationSettings
									,CollapseDirection
									,ShowConfiguration
									,CanCollapse
									,IsCollapsed
									,CanvasId)
	OUTPUT inserted.KeyID INTO @VPPartSettingsMapping (KeyID)
	SELECT x.value('PartName[1]', 'varchar(100)')
			,x.value('ColumnNumber[1]', 'int')
			,x.value('RowNumber[1]', 'int')
			,x.value('Height[1]', 'int')
			,x.value('Width[1]', 'int')
			,x.value('ConfigurationSettings[1]', 'varbinary(max)')
			,x.value('CollapseDirection[1]', 'tinyint')
			,x.value('ShowConfiguration[1]', 'bYN')
			,x.value('CanCollapse[1]', 'bYN')
			,x.value('IsCollapsed[1]', 'bYN')
			,@CanvasId
	FROM @xml.nodes('/root/VPPartSettings/row')e(x);

	UPDATE @VPPartSettingsMapping SET SourceKeyID = x.value('KeyID[1]', 'int')
	FROM @VPPartSettingsMapping t
	INNER JOIN VPPartSettings p on p.KeyID = t.KeyID
	INNER JOIN @xml.nodes('/root/VPPartSettings/row')e(x) ON x.value('PartName[1]', 'varchar(100)') = p.PartName
															AND x.value('ColumnNumber[1]', 'varchar(100)') = p.ColumnNumber
															AND x.value('RowNumber[1]', 'varchar(100)') = p.RowNumber
															AND p.CanvasId = @CanvasId;


	--Processing VPCanvasGridPartSettings------------------------------------------------------
	INSERT INTO VPCanvasGridPartSettings (PartId
										,LastQuery
										,Seq)
	SELECT t.KeyID
			,x.value('LastQuery[1]', 'varchar(128)')
			,x.value('Seq[1]', 'int')
	FROM @xml.nodes('/root/VPCanvasGridPartSettings/row')e(x)
	INNER JOIN @VPPartSettingsMapping t on t.SourceKeyID = x.value('PartId[1]', 'int');

	
	--Processing VPCanvasGridSettings------------------------------------------------------
	DECLARE @VPCanvasGridSettingsMapping TABLE(SourceKeyID int, KeyID int);

	INSERT INTO VPCanvasGridSettings (QueryName
									,Seq
									,CustomName
									,GridLayout
									,Sort
									,MaximumNumberOfRows
									,ShowFilterBar
									,PartId
									,QueryId
									,GridType
									,ShowConfiguration
									,ShowTotals
									,IsDrillThrough
									,SelectedRow)
	OUTPUT inserted.KeyID INTO @VPCanvasGridSettingsMapping (KeyID)
	SELECT x.value('QueryName[1]', 'varchar(128)')
		,x.value('Seq[1]', 'int')
		,x.value('CustomName[1]', 'varchar(128)')
		,x.value('GridLayout[1]', 'varchar(max)')
		,x.value('Sort[1]', 'varchar(128)')
		,x.value('MaximumNumberOfRows[1]', 'int')
		,x.value('ShowFilterBar[1]', 'bYN')
		,t.KeyID
		,x.value('QueryId[1]', 'int')
		,x.value('GridType[1]', 'int')
		,x.value('ShowConfiguration[1]', 'bYN')
		,x.value('ShowTotals[1]', 'bYN')
		,x.value('IsDrillThrough[1]', 'bYN')
		,x.value('SelectedRow[1]', 'int')
	FROM @xml.nodes('/root/VPCanvasGridSettings/row')e(x)
	INNER JOIN @VPPartSettingsMapping t on t.SourceKeyID = x.value('PartId[1]', 'int');

	UPDATE @VPCanvasGridSettingsMapping SET SourceKeyID = x.value('KeyID[1]', 'int')
	FROM @VPCanvasGridSettingsMapping t
	INNER JOIN VPCanvasGridSettings g on g.KeyID = t.KeyID
	INNER JOIN @VPPartSettingsMapping p on p.KeyID = g.PartId
	INNER JOIN @xml.nodes('/root/VPCanvasGridSettings/row')e(x) ON x.value('QueryName[1]', 'varchar(128)') = g.QueryName
															AND x.value('Seq[1]', 'int') = g.Seq
															AND x.value('PartId[1]', 'int') = p.SourceKeyID;
	
	
	--Processing VPCanvasGridColumns------------------------------------------------------
	INSERT INTO VPCanvasGridColumns (GridConfigurationId
									,Name
									,IsVisible
									,Position
									,FilterValue)
	SELECT t.KeyID
			,x.value('Name[1]', 'varchar(128)')
			,x.value('IsVisible[1]', 'bYN')
			,x.value('Position[1]', 'int')
			,x.value('FilterValue[1]', 'varchar(128)')
	FROM @xml.nodes('/root/VPCanvasGridColumns/row')e(x)
	INNER JOIN @VPCanvasGridSettingsMapping t on t.SourceKeyID = x.value('GridConfigurationId[1]', 'int');

	
	--Processing VPCanvasGridGroupedColumns------------------------------------------------------
	INSERT INTO VPCanvasGridGroupedColumns (GridConfigurationId
									,Name
									,ColumnOrder)
	SELECT t.KeyID
			,x.value('Name[1]', 'varchar(128)')
			,x.value('ColumnOrder[1]', 'int')
	FROM @xml.nodes('/root/VPCanvasGridGroupedColumns/row')e(x)
	INNER JOIN @VPCanvasGridSettingsMapping t on t.SourceKeyID = x.value('GridConfigurationId[1]', 'int');

	
	--Processing VPCanvasGridParameters------------------------------------------------------
	INSERT INTO VPCanvasGridParameters (GridConfigurationId
									,Name
									,SqlType
									,ParameterValue)
	SELECT t.KeyID
			,x.value('Name[1]', 'varchar(128)')
			,x.value('SqlType[1]', 'int')
			,x.value('ParameterValue[1]', 'varchar(256)')
	FROM @xml.nodes('/root/VPCanvasGridParameters/row')e(x)
	INNER JOIN @VPCanvasGridSettingsMapping t on t.SourceKeyID = x.value('GridConfigurationId[1]', 'int');

	
	--Processing VPCanvasNavigationSettings------------------------------------------------------
	INSERT INTO VPCanvasNavigationSettings (PartId
									,GridConfigurationID
									,Step
									,ParentGridConfigurationID
									,UserDefaultDrillThrough)
	SELECT t.KeyID
			,g.KeyID
			,x.value('Step[1]', 'int')
			,p.KeyID
			,x.value('UserDefaultDrillThrough[1]', 'bYN')
	FROM @xml.nodes('/root/VPCanvasNavigationSettings/row')e(x) 
	INNER JOIN @VPPartSettingsMapping t on t.SourceKeyID = x.value('PartId[1]', 'int')
	LEFT OUTER JOIN @VPCanvasGridSettingsMapping g on g.SourceKeyID = x.value('GridConfigurationID[1]', 'int')
	LEFT OUTER JOIN @VPCanvasGridSettingsMapping p on p.SourceKeyID = x.value('ParentGridConfigurationID[1]', 'int');

END

GO
GRANT EXECUTE ON  [dbo].[vspVPLoadWorkCenterUserLibrary] TO [public]
GO
