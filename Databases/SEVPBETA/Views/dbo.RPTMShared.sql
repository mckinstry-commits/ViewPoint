SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[RPTMShared] AS 
	/***********************************************
	* Created:
	* Modified: CC 1/21/2008 - 131382 correct handling of standard/custom data
	*
	* Combines standard and custom My Viewpoint Report Template Association information 
	* from vRPTM and vRPTMc.
	*
	* Uses 'instead of triggers' to handle data modifications 
	*
	*******************************************/
	SELECT COALESCE(c.KeyID, s.KeyID) AS KeyID
			, COALESCE(s.ReportID, c.ReportID) AS ReportID
			, COALESCE(s.TemplateName, c.TemplateName) AS TemplateName
			, COALESCE(c.Active, 'Y') AS 'Active'
			,CASE	WHEN c.KeyID IS NULL and s.KeyID IS NOT NULL THEN 'Standard' 
					WHEN c.KeyID IS NOT NULL and s.KeyID IS NOT NULL THEN 'Override' 
					WHEN c.KeyID IS NOT NULL and s.KeyID IS NULL THEN 'Custom' 
					ELSE 'Unknown' END AS RPTMStatus
	FROM vRPTM AS s
	FULL OUTER JOIN vRPTMc AS c ON s.ReportID = c.ReportID AND s.TemplateName = c.TemplateName
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
CREATE TRIGGER [dbo].[vtRPTMSharedd] 
   ON  [dbo].[RPTMShared] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE vRPTMc
	FROM vRPTMc
	INNER JOIN deleted i ON vRPTMc.KeyID = i.KeyID AND vRPTMc.ReportID = i.ReportID

 IF SUSER_SNAME() = 'viewpointcs'
	DELETE vRPTM 
	FROM vRPTM
	INNER JOIN deleted i ON vRPTM.KeyID = i.KeyID AND vRPTM.ReportID = i.ReportID
	
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
CREATE TRIGGER [dbo].[vtRPTMSharedi] 
   ON  [dbo].[RPTMShared] 
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
	INSERT INTO vRPTM (ReportID, TemplateName)
		SELECT i.ReportID, i.TemplateName 
		FROM inserted AS i
		LEFT OUTER JOIN vRPTM AS r ON i.ReportID = r.ReportID AND i.TemplateName = r.TemplateName
		WHERE r.ReportID IS NULL AND r.TemplateName IS NULL
		
ELSE
	INSERT INTO vRPTMc (ReportID, TemplateName, Active)
		SELECT i.ReportID, i.TemplateName, i.Active
		FROM inserted AS i
		LEFT OUTER JOIN vRPTMc AS r ON i.ReportID = r.ReportID AND i.TemplateName = r.TemplateName
		WHERE r.ReportID IS NULL AND r.TemplateName IS NULL
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
CREATE TRIGGER [dbo].[vtRPTMSharedu] 
   ON  [dbo].[RPTMShared] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	UPDATE vRPTM SET
		ReportID = i.ReportID, 
		TemplateName = i.TemplateName
	FROM vRPTM
	INNER JOIN inserted i ON vRPTM.KeyID = i.KeyID AND vRPTM.ReportID = i.ReportID

ELSE
	BEGIN
		/*
		Add entries that don't exist, use "left anti semi join" instead of multiple not in clauses
		by adding the right hand table IS NULL predicate in the where clause it returns values in the left hand table 
		that don't exist in the right hand table
		*/
		INSERT INTO vRPTMc (ReportID, TemplateName, Active)
			SELECT i.ReportID, i.TemplateName, i.Active
			FROM inserted i
			LEFT OUTER JOIN vRPTMc r ON i.ReportID = r.ReportID AND i.TemplateName = r.TemplateName
			WHERE r.ReportID IS NULL AND r.TemplateName IS NULL
		
		UPDATE vRPTMc SET
			ReportID = i.ReportID, 
			TemplateName = i.TemplateName,
			Active = i.Active
		FROM vRPTMc
		INNER JOIN inserted i ON vRPTMc.TemplateName = i.TemplateName AND vRPTMc.ReportID = i.ReportID
	END
	
 DELETE vRPTMc
 FROM vRPTMc c
 INNER JOIN vRPTM s ON c.ReportID = s.ReportID AND c.TemplateName = s.TemplateName 
 WHERE c.Active = 'Y'
 
END
GO
GRANT SELECT ON  [dbo].[RPTMShared] TO [public]
GRANT INSERT ON  [dbo].[RPTMShared] TO [public]
GRANT DELETE ON  [dbo].[RPTMShared] TO [public]
GRANT UPDATE ON  [dbo].[RPTMShared] TO [public]
GO
