SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridQueries AS
	SELECT * FROM vVPGridQueries

	UNION ALL

	SELECT * FROM vVPGridQueriesc

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
CREATE TRIGGER [dbo].[vtVPGridQueriesd] 
   ON  [dbo].[VPGridQueries] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPGridQueries 
	FROM vVPGridQueries
	INNER JOIN deleted d ON vVPGridQueries.KeyID = d.KeyID AND vVPGridQueries.QueryName = d.QueryName AND d.IsStandard = 'Y';

	DELETE vVPGridQueriesc		
	FROM vVPGridQueriesc
	INNER JOIN deleted d ON vVPGridQueriesc.KeyID = d.KeyID AND vVPGridQueriesc.QueryName = d.QueryName AND d.IsStandard = 'N';
	
	DELETE vVPCanvasGridSettings
	FROM vVPCanvasGridSettings
	INNER JOIN DELETED d ON vVPCanvasGridSettings.QueryName = d.QueryName;
	
	DELETE vVPCanvasTreeItems
	FROM vVPCanvasTreeItems
	INNER JOIN DELETED d ON Item = d.QueryName;
	
	DELETE vVPPartFormChangedMessages
	FROM vVPPartFormChangedMessages
	INNER JOIN DELETED d ON FormName = d.QueryName;
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: HH 3/21/2012 TK-13339 added QueryType field to insert statement
*			HH 3/23/2012 TK-13339 call vspVPGridQueryAssociationInsertDefaults for defaults 
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueriesi] 
   ON  [dbo].[VPGridQueries] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPGridQueries (QueryName, QueryTitle, QueryDescription, QueryType, Query, Notes)
		SELECT QueryName, QueryTitle, QueryDescription, QueryType, Query, Notes FROM inserted
ELSE
	INSERT INTO vVPGridQueriesc (QueryName, QueryTitle, QueryDescription, QueryType, Query, Notes)
		SELECT QueryName, QueryTitle, QueryDescription, QueryType, Query, Notes FROM inserted

	-- Insert VPGridQueryAssociation Defaults
	DECLARE @QueryName varchar(50)
	SELECT @QueryName = QueryName 
	FROM inserted
	EXEC vspVPGridQueryAssociationInsertDefaults @QueryName, ''
END 
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: HH 3/21/2012 TK-13339 added QueryType field to update statement
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueriesu] 
   ON  [dbo].[VPGridQueries] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vVPGridQueries SET
		QueryName = i.QueryName,
		QueryTitle = i.QueryTitle,
		QueryDescription = i.QueryDescription,
		QueryType = i.QueryType,
		Query = i.Query, 
		Notes = i.Notes
	FROM vVPGridQueries
	INNER JOIN inserted i ON vVPGridQueries.KeyID = i.KeyID AND vVPGridQueries.QueryName = i.QueryName AND i.IsStandard = 'Y'

	UPDATE vVPGridQueriesc SET
		QueryName = i.QueryName,
		QueryTitle = i.QueryTitle,
		QueryDescription = i.QueryDescription,
		QueryType = i.QueryType,
		Query = i.Query, 
		Notes = i.Notes
	FROM vVPGridQueriesc
	INNER JOIN inserted i ON vVPGridQueriesc.KeyID = i.KeyID AND vVPGridQueriesc.QueryName = i.QueryName AND i.IsStandard = 'N'
END
GO
GRANT SELECT ON  [dbo].[VPGridQueries] TO [public]
GRANT INSERT ON  [dbo].[VPGridQueries] TO [public]
GRANT DELETE ON  [dbo].[VPGridQueries] TO [public]
GRANT UPDATE ON  [dbo].[VPGridQueries] TO [public]
GRANT SELECT ON  [dbo].[VPGridQueries] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPGridQueries] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPGridQueries] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPGridQueries] TO [Viewpoint]
GO
