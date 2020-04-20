SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[RPRQShared] AS
	SELECT * FROM vRPRQ

	UNION ALL

	SELECT * FROM vRPRQc

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
CREATE TRIGGER [dbo].[vtRPRQSharedd] 
   ON  [dbo].[RPRQShared] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	DELETE vRPRQ 
	FROM vRPRQ
	INNER JOIN deleted i ON vRPRQ.KeyID = i.KeyID AND vRPRQ.DataSetName = i.DataSetName

ELSE
	DELETE vRPRQc 
	FROM vRPRQc
	INNER JOIN deleted i ON vRPRQc.KeyID = i.KeyID AND vRPRQc.DataSetName = i.DataSetName
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: CC 9/8/2008
* Modified: CC 1/21/2009 - 131389 Prevent duplicate queries from being entered.
*
*	This trigger sends data to the correct underlying tables
*
************************************************************************/
CREATE TRIGGER [dbo].[vtRPRQSharedi] 
   ON  [dbo].[RPRQShared] 
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
	INSERT INTO vRPRQ (ReportID, DataSetName, QueryText)
		SELECT i.ReportID, i.DataSetName, i.QueryText 
		FROM inserted AS i
		LEFT OUTER JOIN vRPRQ AS r ON i.ReportID = r.ReportID AND i.DataSetName = r.DataSetName 
		WHERE r.ReportID IS NULL AND r.DataSetName IS NULL
		
ELSE
	INSERT INTO vRPRQc (ReportID, DataSetName, QueryText)
		SELECT i.ReportID, i.DataSetName, i.QueryText
		FROM inserted AS i
		LEFT OUTER JOIN vRPRQ AS r ON i.ReportID = r.ReportID AND i.DataSetName = r.DataSetName 
		WHERE r.ReportID IS NULL AND r.DataSetName IS NULL
		
END
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
CREATE TRIGGER [dbo].[vtRPRQSharedu] 
   ON  [dbo].[RPRQShared] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF UPPER(SUSER_SNAME())='VIEWPOINTCS'
	UPDATE vRPRQ SET
		ReportID = i.ReportID,
		DataSetName = i.DataSetName,
		QueryText = i.QueryText
	FROM vRPRQ
	INNER JOIN inserted i ON vRPRQ.KeyID = i.KeyID AND vRPRQ.DataSetName = i.DataSetName

ELSE
	UPDATE vRPRQc SET
		ReportID = i.ReportID,
		DataSetName = i.DataSetName,
		QueryText = i.QueryText
	FROM vRPRQc
	INNER JOIN inserted i ON vRPRQc.KeyID = i.KeyID AND vRPRQc.DataSetName = i.DataSetName
END
GO
GRANT SELECT ON  [dbo].[RPRQShared] TO [public]
GRANT INSERT ON  [dbo].[RPRQShared] TO [public]
GRANT DELETE ON  [dbo].[RPRQShared] TO [public]
GRANT UPDATE ON  [dbo].[RPRQShared] TO [public]
GO
