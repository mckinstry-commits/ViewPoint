SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridQueryLinkParameters
AS
	SELECT     	[QueryName], 
				[RelatedQueryName], 
				[ParameterName], 
				[MatchingColumn], 
				[UseDefault],
				[IsStandard], 
				[KeyID]
	FROM         vVPGridQueryLinkParameters

	UNION ALL
	-- use column names instead of * because of inconsistency in standard/custom table field order
	SELECT     	[QueryName], 
				[RelatedQueryName], 
				[ParameterName], 
				[MatchingColumn], 
				[UseDefault],
				[IsStandard], 
				[KeyID]
	FROM         vVPGridQueryLinkParametersc
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: GPT 6/01/2012
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinkParametersd] 
   ON  [dbo].[VPGridQueryLinkParameters] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPGridQueryLinkParameters
	FROM vVPGridQueryLinkParameters
	INNER JOIN deleted d ON vVPGridQueryLinkParameters.KeyID = d.KeyID AND vVPGridQueryLinkParameters.QueryName = d.QueryName AND d.IsStandard = 'Y'

	DELETE vVPGridQueryLinkParametersc
	FROM vVPGridQueryLinkParametersc
	INNER JOIN deleted d ON vVPGridQueryLinkParametersc.KeyID = d.KeyID AND vVPGridQueryLinkParametersc.QueryName = d.QueryName AND d.IsStandard = 'N'

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: GPT 6/01/2012
* Modified: 
*			
*			
*			
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinkParametersi] 
   ON  [dbo].[VPGridQueryLinkParameters] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	INSERT INTO vVPGridQueryLinkParameters ( [QueryName], [RelatedQueryName], [ParameterName], [MatchingColumn], [UseDefault] )
		SELECT [QueryName], [RelatedQueryName], [ParameterName], [MatchingColumn], [UseDefault] FROM inserted
ELSE
	INSERT INTO vVPGridQueryLinkParametersc ( [QueryName], [RelatedQueryName], [ParameterName], [MatchingColumn], [UseDefault] )
		SELECT [QueryName], [RelatedQueryName], [ParameterName], [MatchingColumn], [UseDefault] FROM inserted
END



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: GPT 6/01/2012
* Modified: 
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtVPGridQueryLinkParametersu] 
   ON  [dbo].[VPGridQueryLinkParameters] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE vVPGridQueryLinkParameters SET
		[QueryName] = i.[QueryName],
		[RelatedQueryName] = i.[RelatedQueryName],
		[ParameterName] = i.[ParameterName],
		[MatchingColumn] = i.[MatchingColumn],
		[UseDefault] = i.[UseDefault]
	FROM vVPGridQueryLinkParameters
	INNER JOIN inserted i ON vVPGridQueryLinkParameters.KeyID = i.KeyID AND vVPGridQueryLinkParameters.QueryName = i.QueryName AND i.IsStandard = 'Y'

UPDATE vVPGridQueryLinkParametersc SET
		[QueryName] = i.[QueryName],
		[RelatedQueryName] = i.[RelatedQueryName],
		[ParameterName] = i.[ParameterName],
		[MatchingColumn] = i.[MatchingColumn],
		[UseDefault] = i.[UseDefault]
	FROM vVPGridQueryLinkParametersc
	INNER JOIN inserted i ON vVPGridQueryLinkParametersc.KeyID = i.KeyID AND vVPGridQueryLinkParametersc.QueryName = i.QueryName AND i.IsStandard = 'N'

END



GO
GRANT SELECT ON  [dbo].[VPGridQueryLinkParameters] TO [public]
GRANT INSERT ON  [dbo].[VPGridQueryLinkParameters] TO [public]
GRANT DELETE ON  [dbo].[VPGridQueryLinkParameters] TO [public]
GRANT UPDATE ON  [dbo].[VPGridQueryLinkParameters] TO [public]
GRANT SELECT ON  [dbo].[VPGridQueryLinkParameters] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPGridQueryLinkParameters] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPGridQueryLinkParameters] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPGridQueryLinkParameters] TO [Viewpoint]
GO
