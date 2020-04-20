SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[pvReportParameterControlShared] AS


--SELECT ISNULL(c. ) AS pReportParametersPortalControl
--SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
--	ISNULL(c.PortalControlID, t.PortalControlID) AS PortalControlID,
--	ISNULL(c.Access, t.Access) AS Access
--FROM dbo.pReportControlsCustom AS c
--FULL OUTER JOIN dbo.pReportControls AS t ON t.ReportID = c.ReportID


SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
	ISNULL(c.ParameterName, t.ParameterName) AS ParameterName,
	ISNULL(c.PortalControlID, t.PortalControlID) AS PortalControlID,
	ISNULL(c.PortalParameterDefault, t.PortalParameterDefault) AS PortalParameterDefault,
	ISNULL(c.PortalAccess, t.PortalAccess) AS PortalAccess,
	ISNULL(c.DetailsFieldID, t.DetailsFieldID) AS DetailsFieldID,
	CASE 
		WHEN c.ReportID IS NULL THEN 'Standard'
		WHEN t.ReportID IS NULL THEN 'Custom'
		ELSE 'Override'
	END AS Status
FROM dbo.pReportParametersPortalControlCustom AS c
FULL OUTER JOIN dbo.pReportParametersPortalControl AS t ON t.ReportID = c.ReportID
AND t.ParameterName = c.ParameterName AND t.PortalControlID = c.PortalControlID



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtdReportParametersPortalControlShared]
   ON  [dbo].[pvReportParameterControlShared]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF suser_name() = 'viewpointcs'
	BEGIN
		DELETE dbo.pReportParametersPortalControl
        FROM dbo.pReportParametersPortalControl
			INNER JOIN DELETED ON pReportParametersPortalControl.ReportID = DELETED.ReportID
				AND pReportParametersPortalControl.ParameterName = DELETED.ParameterName
				AND pReportParametersPortalControl.PortalControlID = DELETED.PortalControlID
	END

	DELETE dbo.pReportParametersPortalControlCustom
    FROM dbo.pReportParametersPortalControlCustom
		INNER JOIN DELETED ON pReportParametersPortalControlCustom.ReportID = DELETED.ReportID
			AND pReportParametersPortalControlCustom.ParameterName = DELETED.ParameterName
			AND pReportParametersPortalControlCustom.PortalControlID = DELETED.PortalControlID


END


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtiReportParametersPortalControlShared]
   ON  [dbo].[pvReportParameterControlShared]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF suser_name() = 'viewpointcs'
	BEGIN
		INSERT INTO dbo.pReportParametersPortalControl
			(ReportID
           ,ParameterName
           ,PortalControlID
           ,PortalParameterDefault
           ,PortalAccess
           ,DetailsFieldID)
        SELECT ReportID, ParameterName, PortalControlID, PortalParameterDefault, PortalAccess, DetailsFieldID
        FROM INSERTED
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportParametersPortalControlCustom
			(ReportID
           ,ParameterName
           ,PortalControlID
           ,PortalParameterDefault
           ,PortalAccess
           ,DetailsFieldID)
        SELECT ReportID, ParameterName, PortalControlID, PortalParameterDefault, PortalAccess, DetailsFieldID
        FROM INSERTED
	END

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtuReportParametersPortalControlShared]
   ON  [dbo].[pvReportParameterControlShared]
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE dbo.pReportParametersPortalControlCustom
		SET ReportID = INSERTED.ReportID
		,ParameterName = INSERTED.ParameterName
		,PortalControlID = INSERTED.PortalControlID
		,PortalParameterDefault = INSERTED.PortalParameterDefault
		,PortalAccess = INSERTED.PortalAccess
		,DetailsFieldID = INSERTED.DetailsFieldID
	FROM pReportParametersPortalControlCustom
		INNER JOIN INSERTED ON pReportParametersPortalControlCustom.ReportID = INSERTED.ReportID
			AND pReportParametersPortalControlCustom.ParameterName = INSERTED.ParameterName
			AND pReportParametersPortalControlCustom.PortalControlID = INSERTED.PortalControlID

    IF suser_name() = 'viewpointcs'
	BEGIN
		UPDATE dbo.pReportParametersPortalControl
			SET ReportID = INSERTED.ReportID
			,ParameterName = INSERTED.ParameterName
			,PortalControlID = INSERTED.PortalControlID
			,PortalParameterDefault = INSERTED.PortalParameterDefault
			,PortalAccess = INSERTED.PortalAccess
			,DetailsFieldID = INSERTED.DetailsFieldID
		FROM pReportParametersPortalControl
			INNER JOIN INSERTED ON pReportParametersPortalControl.ReportID = INSERTED.ReportID
				AND pReportParametersPortalControl.ParameterName = INSERTED.ParameterName
				AND pReportParametersPortalControl.PortalControlID = INSERTED.PortalControlID
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportParametersPortalControlCustom
			(ReportID
			,ParameterName
			,PortalControlID
			,PortalParameterDefault
			,PortalAccess
			,DetailsFieldID)
        SELECT ReportID, ParameterName, PortalControlID, PortalParameterDefault, PortalAccess, DetailsFieldID
        FROM INSERTED
        WHERE NOT EXISTS (
			SELECT TOP 1 1 
			FROM pReportParametersPortalControlCustom 
			WHERE INSERTED.ReportID = pReportParametersPortalControlCustom.ReportID
				AND INSERTED.ParameterName = pReportParametersPortalControlCustom.ParameterName
				AND INSERTED.PortalControlID = pReportParametersPortalControlCustom.PortalControlID)
	END
	


END

GO
GRANT SELECT ON  [dbo].[pvReportParameterControlShared] TO [public]
GRANT INSERT ON  [dbo].[pvReportParameterControlShared] TO [public]
GRANT DELETE ON  [dbo].[pvReportParameterControlShared] TO [public]
GRANT UPDATE ON  [dbo].[pvReportParameterControlShared] TO [public]
GRANT SELECT ON  [dbo].[pvReportParameterControlShared] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvReportParameterControlShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvReportParameterControlShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvReportParameterControlShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvReportParameterControlShared] TO [Viewpoint]
GO
