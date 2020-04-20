SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridColumns AS
	/***********************************************
	* Created:
	* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
	*			CC 10/13/2009 - 132545 - Add column to support datatype definition for My Viewpoint queries
	*			HH 5/30/2012 - TK-15193 - added Suppress column
	*			HH 10/12/2012 - TK-18457 added IsNotifierKeyField
	*
	* Combines standard and custom My Viewpoint Grid Colum information 
	* from vVPGridColumns and vVPGridColumnsc.
	*
	* Uses 'instead of triggers' to handle data modifications 
	*
	*******************************************/
	SELECT	COALESCE(s.QueryName, c.QueryName) AS QueryName
			, COALESCE(s.ColumnName, c.ColumnName) AS ColumnName
			, COALESCE(c.DefaultOrder, s.DefaultOrder) AS DefaultOrder
			, COALESCE(c.VisibleOnGrid, s.VisibleOnGrid) AS VisibleOnGrid
			, COALESCE(c.IsStandard, s.IsStandard) AS IsStandard
			, COALESCE(c.Datatype, s.Datatype) AS Datatype
			, COALESCE(c.KeyID, s.KeyID) AS KeyID
			, COALESCE(c.ExcludeFromAggregation, s.ExcludeFromAggregation) AS ExcludeFromAggregation
			, COALESCE(c.ExcludeFromQuery, s.ExcludeFromQuery) AS ExcludeFromQuery
			, COALESCE(c.IsNotifierKeyField, s.IsNotifierKeyField) AS IsNotifierKeyField
	FROM vVPGridColumns AS s
	FULL OUTER JOIN vVPGridColumnsc AS c ON s.QueryName = c.QueryName AND s.ColumnName = c.ColumnName

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridColumnsd] 
   ON  [dbo].[VPGridColumns] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPGridColumnsc 
	FROM vVPGridColumnsc
	INNER JOIN deleted d ON vVPGridColumnsc.KeyID = d.KeyID AND vVPGridColumnsc.QueryName = d.QueryName  AND d.IsStandard = 'N'
 
 IF SUSER_SNAME() = 'viewpointcs'
	DELETE vVPGridColumns 
	FROM vVPGridColumns
	INNER JOIN deleted d ON vVPGridColumns.KeyID = d.KeyID AND vVPGridColumns.QueryName = d.QueryName  AND d.IsStandard = 'Y'
	
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
			CC 10/13/2009 - #132545 Add column to support datatype definition for My Viewpoint queries
*			HH 5/30/2012 - TK-15193 added Suppress column
*			HH 10/12/2012 - TK-18457 added IsNotifierKeyField
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridColumnsi] 
   ON  [dbo].[VPGridColumns] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
/*
Add entries that don't exist, use "left anti semi join" instead of multiple not in clauses
by adding the right hand table IS NULL predicate in the where clause it returns values in the left hand table 
that don't exist in the right hand table
*/

IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPGridColumns (QueryName, ColumnName, DefaultOrder, VisibleOnGrid, Datatype, ExcludeFromAggregation, ExcludeFromQuery, IsNotifierKeyField)
		SELECT i.QueryName, i.ColumnName, i.DefaultOrder, i.VisibleOnGrid, i.Datatype, i.ExcludeFromAggregation, i.ExcludeFromQuery, i.IsNotifierKeyField
		FROM inserted AS i 
		LEFT OUTER JOIN vVPGridColumns AS g ON i.QueryName = g.QueryName AND i.ColumnName = g.ColumnName
		WHERE g.QueryName IS NULL AND g.ColumnName IS NULL
ELSE
	INSERT INTO vVPGridColumnsc (QueryName, ColumnName, DefaultOrder, VisibleOnGrid, Datatype, ExcludeFromAggregation, ExcludeFromQuery, IsNotifierKeyField)
		SELECT i.QueryName, i.ColumnName, i.DefaultOrder, i.VisibleOnGrid, i.Datatype, i.ExcludeFromAggregation, i.ExcludeFromQuery, i.IsNotifierKeyField  
		FROM inserted AS i 
		LEFT OUTER JOIN vVPGridColumnsc AS g ON i.QueryName = g.QueryName AND i.ColumnName = g.ColumnName
		WHERE g.QueryName IS NULL AND g.ColumnName IS NULL

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
*			HH 10/12/2012 - TK-18457 added IsNotifierKeyField
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridColumnsu] 
   ON  [dbo].[VPGridColumns] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 IF SUSER_SNAME()='viewpointcs'
 	UPDATE vVPGridColumns SET
		QueryName = i.QueryName,
		ColumnName = i.ColumnName,
		DefaultOrder = i.DefaultOrder,
		VisibleOnGrid = i.VisibleOnGrid,
		Datatype = i.Datatype,
		ExcludeFromAggregation = i.ExcludeFromAggregation,
		ExcludeFromQuery = i.ExcludeFromQuery,
		IsNotifierKeyField = i.IsNotifierKeyField
	FROM vVPGridColumns
	INNER JOIN inserted i ON vVPGridColumns.KeyID = i.KeyID AND 
							vVPGridColumns.QueryName = i.QueryName AND 
							i.IsStandard = 'Y';
		
 ELSE
	BEGIN 
		/*
		Add entries that don't exist, use "left anti semi join" instead of multiple not in clauses
		by adding the right hand table IS NULL predicate in the where clause it returns values in the left hand table 
		that don't exist in the right hand table
		*/
		INSERT INTO vVPGridColumnsc (QueryName, ColumnName, DefaultOrder, VisibleOnGrid, Datatype, ExcludeFromAggregation, ExcludeFromQuery, IsNotifierKeyField)
			SELECT i.QueryName, i.ColumnName, i.DefaultOrder, i.VisibleOnGrid, i.Datatype, i.ExcludeFromAggregation, i.ExcludeFromQuery, i.IsNotifierKeyField
			FROM inserted AS i
			LEFT OUTER JOIN vVPGridColumnsc AS g ON g.QueryName = i.QueryName AND g.ColumnName = i.ColumnName
			WHERE g.QueryName IS NULL AND g.ColumnName IS NULL;
	 
		UPDATE vVPGridColumnsc SET
			QueryName = i.QueryName,
			ColumnName = i.ColumnName,
			DefaultOrder = i.DefaultOrder,
			VisibleOnGrid = i.VisibleOnGrid,
			Datatype = i.Datatype,
			ExcludeFromAggregation = i.ExcludeFromAggregation,
			ExcludeFromQuery = i.ExcludeFromQuery,
			IsNotifierKeyField = i.IsNotifierKeyField
		FROM vVPGridColumnsc
		INNER JOIN inserted i ON vVPGridColumnsc.KeyID = i.KeyID AND vVPGridColumnsc.QueryName = i.QueryName  AND i.IsStandard = 'N';

	END

--remove custom entries matching standard entries
 DELETE vVPGridColumnsc
 FROM vVPGridColumnsc c
 INNER JOIN vVPGridColumns s ON c.QueryName = s.QueryName AND c.ColumnName = s.ColumnName AND c.DefaultOrder = s.DefaultOrder
 --all standard entries will be VisibleOnGrid, with inactive ('N') being the override
 WHERE c.VisibleOnGrid = 'Y';

END 
GO
GRANT SELECT ON  [dbo].[VPGridColumns] TO [public]
GRANT INSERT ON  [dbo].[VPGridColumns] TO [public]
GRANT DELETE ON  [dbo].[VPGridColumns] TO [public]
GRANT UPDATE ON  [dbo].[VPGridColumns] TO [public]
GRANT SELECT ON  [dbo].[VPGridColumns] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPGridColumns] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPGridColumns] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPGridColumns] TO [Viewpoint]
GO
