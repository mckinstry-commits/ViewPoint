SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPGridQueryAssociation AS 
	/***********************************************
	* Created:
	* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
	*
	* Combines standard and custom My Viewpoint Grid Query information 
	* from vVPGridQueryAssociation and vVPGridQueryAssociationc.
	*
	* Uses 'instead of triggers' to handle data modifications 
	*
	*******************************************/
	SELECT	COALESCE(s.KeyID, c.KeyID) AS KeyID
			, COALESCE(c.QueryName, s.QueryName) AS QueryName
			, COALESCE(c.TemplateName, s.TemplateName) AS TemplateName
			, COALESCE(c.Active,'Y') AS Active
			, COALESCE(c.IsStandard, s.IsStandard) AS IsStandard
	FROM vVPGridQueryAssociation AS s
	FULL OUTER JOIN vVPGridQueryAssociationc AS c ON s.TemplateName = c.TemplateName AND s.QueryName = c.QueryName

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
CREATE TRIGGER [dbo].[vtVPGridQueryAssociationd] 
   ON  [dbo].[VPGridQueryAssociation] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vVPGridQueryAssociationc 		
	FROM vVPGridQueryAssociationc
	INNER JOIN deleted d ON vVPGridQueryAssociationc.KeyID = d.KeyID AND vVPGridQueryAssociationc.QueryName = d.QueryName AND vVPGridQueryAssociationc.TemplateName = d.TemplateName AND d.IsStandard = 'N'

 IF SUSER_SNAME()= 'viewpointcs'
	DELETE FROM vVPGridQueryAssociation 		
	FROM vVPGridQueryAssociation
	INNER JOIN deleted d ON vVPGridQueryAssociation.KeyID = d.KeyID AND vVPGridQueryAssociation.QueryName = d.QueryName AND vVPGridQueryAssociation.TemplateName = d.TemplateName AND d.IsStandard = 'Y'



END
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
CREATE TRIGGER [dbo].[vtVPGridQueryAssociationi] 
   ON  [dbo].[VPGridQueryAssociation] 
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
	INSERT INTO vVPGridQueryAssociation (QueryName, TemplateName)
		SELECT i.QueryName, i.TemplateName 
		FROM inserted AS i
		LEFT OUTER JOIN vVPGridQueryAssociation AS g ON i.QueryName = g.QueryName AND i.TemplateName = g.TemplateName
		WHERE g.QueryName IS NULL AND g.TemplateName IS NULL
		
ELSE
	INSERT INTO vVPGridQueryAssociationc (QueryName, TemplateName, Active)
		SELECT i.QueryName, i.TemplateName, i.Active
		FROM inserted AS i
		LEFT OUTER JOIN vVPGridQueryAssociationc AS g ON i.QueryName = g.QueryName AND i.TemplateName = g.TemplateName
		WHERE g.QueryName IS NULL AND g.TemplateName IS NULL

END 
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
CREATE TRIGGER [dbo].[vtVPGridQueryAssociationu] 
   ON  [dbo].[VPGridQueryAssociation] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 IF SUSER_SNAME()='viewpointcs'
	UPDATE vVPGridQueryAssociation SET
		QueryName = i.QueryName, 
		TemplateName = i.TemplateName,
		Active = i.Active
	FROM vVPGridQueryAssociation
	INNER JOIN inserted i ON vVPGridQueryAssociation.QueryName = i.QueryName AND 
							vVPGridQueryAssociation.TemplateName = i.TemplateName AND 
							i.IsStandard = 'Y'
	
 ELSE
	BEGIN 
		/*
		Add entries that don't exist, use "left anti semi join" instead of multiple not in clauses
		by adding the right hand table IS NULL predicate in the where clause it returns values in the left hand table 
		that don't exist in the right hand table
		*/
		INSERT INTO vVPGridQueryAssociationc (QueryName, TemplateName, Active, IsStandard)
			SELECT i.QueryName, i.TemplateName, i.Active, 'N'
			FROM inserted i
			LEFT OUTER JOIN vVPGridQueryAssociationc q ON q.QueryName = i.QueryName AND q.TemplateName = i.TemplateName
			WHERE q.QueryName IS NULL AND q.TemplateName IS NULL
	 
		UPDATE vVPGridQueryAssociationc SET
			QueryName = i.QueryName, 
			TemplateName = i.TemplateName,
			Active = i.Active
		FROM vVPGridQueryAssociationc
		INNER JOIN inserted i ON vVPGridQueryAssociationc.QueryName = i.QueryName AND 
								vVPGridQueryAssociationc.TemplateName = i.TemplateName AND 
								i.IsStandard = 'N'
	END

--remove custom entries matching standard entries
 DELETE vVPGridQueryAssociationc
 FROM vVPGridQueryAssociationc c
 INNER JOIN vVPGridQueryAssociation s ON c.QueryName = s.QueryName AND c.TemplateName = s.TemplateName
 --all standard entries will be active, with inactive ('N') being the override
 WHERE c.Active = 'Y' 
 
END 
GO
GRANT SELECT ON  [dbo].[VPGridQueryAssociation] TO [public]
GRANT INSERT ON  [dbo].[VPGridQueryAssociation] TO [public]
GRANT DELETE ON  [dbo].[VPGridQueryAssociation] TO [public]
GRANT UPDATE ON  [dbo].[VPGridQueryAssociation] TO [public]
GRANT SELECT ON  [dbo].[VPGridQueryAssociation] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPGridQueryAssociation] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPGridQueryAssociation] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPGridQueryAssociation] TO [Viewpoint]
GO
