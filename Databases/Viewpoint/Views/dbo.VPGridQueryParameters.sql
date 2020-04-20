SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridQueryParameters
AS
SELECT     *
FROM         vVPGridQueryParameters
UNION ALL
SELECT     *
FROM         vVPGridQueryParametersc

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryParametersd] 
   ON  [dbo].[VPGridQueryParameters] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPGridQueryParameters
	FROM vVPGridQueryParameters
	INNER JOIN deleted d ON vVPGridQueryParameters.KeyID = d.KeyID AND vVPGridQueryParameters.QueryName = d.QueryName AND d.IsStandard = 'Y'

	DELETE vVPGridQueryParametersc
	FROM vVPGridQueryParametersc
	INNER JOIN deleted d ON vVPGridQueryParametersc.KeyID = d.KeyID AND vVPGridQueryParametersc.QueryName = d.QueryName AND d.IsStandard = 'N'

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 3/5/2009 - Issue #132493 - Correct insert trigger for other values
*			ChrisG 3/17/11 - TK-02695 - Added Lookup
*			HH 3/23/12 - TK-13339 - Added Comparison and Operator
*			HH 4/27/12 - TK-14571 - Added DefaultOrder
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryParametersi] 
   ON  [dbo].[VPGridQueryParameters] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPGridQueryParameters ( QueryName, Seq, ColumnName, ParameterName, Comparison, Value, Operator, DataType, IsVisible, [Description], DefaultType, DefaultOrder, IsStandard, InputType, InputLength, Prec, [Lookup] )
		SELECT QueryName, Seq, ColumnName, ParameterName, Comparison, Value, Operator, DataType, IsVisible, [Description], DefaultType, DefaultOrder, 'Y', InputType, InputLength, Prec, [Lookup] FROM inserted
ELSE
	INSERT INTO vVPGridQueryParametersc ( QueryName, Seq, ColumnName, ParameterName, Comparison, Value, Operator, DataType, IsVisible, [Description], DefaultType, DefaultOrder, IsStandard, InputType, InputLength, Prec, [Lookup] )
		SELECT QueryName, Seq, ColumnName, ParameterName, Comparison, Value, Operator, DataType, IsVisible, [Description], DefaultType, DefaultOrder, 'N', InputType, InputLength, Prec, [Lookup]  FROM inserted
END



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 3/5/2009 - Issue #132493 - Update parameter type, length, and precision
*			ChrisG 3/17/11 - TK-02695 - Added Lookup and fixed Description (not updating)
*			HH 3/23/12 - TK-13339 - Added Comparison and Operator
*			HH 4/27/12 - TK-14571 - Added DefaultOrder
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryParametersu] 
   ON  [dbo].[VPGridQueryParameters] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vVPGridQueryParameters SET
		QueryName = i.QueryName,
		Seq = i.Seq,
		ColumnName = i.ColumnName,
		ParameterName = i.ParameterName,
		Comparison = i.Comparison,
		[Value] = i.[Value],
		Operator = i.Operator,
		DataType = i.DataType,
		IsVisible = i.IsVisible,
		DefaultType = i.DefaultType,
		DefaultOrder = i.DefaultOrder,
		InputType = i.InputType,
		InputLength = i.InputLength,
		Prec = i.Prec,
		[Description] = i.[Description],
		[Lookup] = i.[Lookup]
	FROM vVPGridQueryParameters
	INNER JOIN inserted i ON vVPGridQueryParameters.KeyID = i.KeyID AND vVPGridQueryParameters.QueryName = i.QueryName AND i.IsStandard = 'Y'

UPDATE vVPGridQueryParametersc SET
		QueryName = i.QueryName,
		Seq = i.Seq,
		ColumnName = i.ColumnName,
		ParameterName = i.ParameterName,
		Comparison = i.Comparison,
		[Value] = i.[Value],
		Operator = i.Operator,
		DataType = i.DataType,
		IsVisible = i.IsVisible,
		DefaultType = i.DefaultType,
		DefaultOrder = i.DefaultOrder,
		InputType = i.InputType,
		InputLength = i.InputLength,
		Prec = i.Prec,
		[Description] = i.[Description],
		[Lookup] = i.[Lookup]
	FROM vVPGridQueryParametersc
	INNER JOIN inserted i ON vVPGridQueryParametersc.KeyID = i.KeyID AND vVPGridQueryParametersc.QueryName = i.QueryName AND i.IsStandard = 'N'

END



GO
GRANT SELECT ON  [dbo].[VPGridQueryParameters] TO [public]
GRANT INSERT ON  [dbo].[VPGridQueryParameters] TO [public]
GRANT DELETE ON  [dbo].[VPGridQueryParameters] TO [public]
GRANT UPDATE ON  [dbo].[VPGridQueryParameters] TO [public]
GO
