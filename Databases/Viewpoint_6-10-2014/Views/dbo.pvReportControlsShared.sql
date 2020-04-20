SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[pvReportControlsShared] AS

SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
	ISNULL(c.PortalControlID, t.PortalControlID) AS PortalControlID,
	ISNULL(c.Access, t.Access) AS Access,
	CASE 
		WHEN c.ReportID IS NULL THEN 'Standard'
		WHEN t.ReportID IS NULL THEN 'Custom'
		ELSE 'Override'
	END AS Status,
	CASE WHEN ISNULL(c.Access, t.Access) = 1 THEN 'Y' ELSE 'N' END AS AccessASbYN
FROM dbo.pReportControlsCustom AS c
FULL OUTER JOIN dbo.pReportControls AS t ON t.ReportID = c.ReportID
	AND t.PortalControlID = c.PortalControlID



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
CREATE TRIGGER [dbo].[vtdReportControlsShared]
   ON  [dbo].[pvReportControlsShared]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF suser_name() = 'viewpointcs'
	BEGIN
		DELETE dbo.pReportControls
        FROM dbo.pReportControls
			INNER JOIN DELETED ON pReportControls.ReportID = DELETED.ReportID
				AND pReportControls.PortalControlID = DELETED.PortalControlID
	END

	DELETE dbo.pReportControlsCustom
    FROM dbo.pReportControlsCustom
		INNER JOIN DELETED ON pReportControlsCustom.ReportID = DELETED.ReportID
			AND pReportControlsCustom.PortalControlID = DELETED.PortalControlID

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
CREATE TRIGGER [dbo].[vtiReportControlsShared]
   ON  [dbo].[pvReportControlsShared]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF suser_name() = 'viewpointcs'
	BEGIN
		INSERT INTO dbo.pReportControls
           (ReportID
           ,PortalControlID
           ,Access)
        SELECT ReportID, PortalControlID, CASE WHEN AccessASbYN = 'Y' THEN 1 ELSE 0 END
        FROM INSERTED
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportControlsCustom
           (ReportID
           ,PortalControlID
           ,Access)
        SELECT ReportID, PortalControlID, CASE WHEN AccessASbYN = 'Y' THEN 1 ELSE 0 END
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
CREATE TRIGGER [dbo].[vtuReportControlsShared]
   ON  [dbo].[pvReportControlsShared]
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE dbo.pReportControlsCustom
	SET ReportID = INSERTED.ReportID
	  ,PortalControlID = INSERTED.PortalControlID
	  ,Access = CASE WHEN INSERTED.AccessASbYN = 'Y' THEN 1 ELSE 0 END
	FROM dbo.pReportControlsCustom
		INNER JOIN INSERTED ON pReportControlsCustom.ReportID = INSERTED.ReportID
			AND pReportControlsCustom.PortalControlID = INSERTED.PortalControlID

    IF suser_name() = 'viewpointcs'
	BEGIN
		UPDATE dbo.pReportControls
		SET ReportID = INSERTED.ReportID
		  ,PortalControlID = INSERTED.PortalControlID
		  ,Access = CASE WHEN INSERTED.AccessASbYN = 'Y' THEN 1 ELSE 0 END
		FROM dbo.pReportControls
			INNER JOIN INSERTED ON pReportControls.ReportID = INSERTED.ReportID
				AND pReportControls.PortalControlID = INSERTED.PortalControlID
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportControlsCustom
           (ReportID
           ,PortalControlID
           ,Access)
        SELECT ReportID, PortalControlID, CASE WHEN AccessASbYN = 'Y' THEN 1 ELSE 0 END
        FROM INSERTED
        WHERE NOT EXISTS (
			SELECT TOP 1 1 
			FROM pReportControlsCustom
			WHERE ReportID = INSERTED.ReportID
				AND PortalControlID = INSERTED.PortalControlID)
	END

END

GO
GRANT SELECT ON  [dbo].[pvReportControlsShared] TO [public]
GRANT INSERT ON  [dbo].[pvReportControlsShared] TO [public]
GRANT DELETE ON  [dbo].[pvReportControlsShared] TO [public]
GRANT UPDATE ON  [dbo].[pvReportControlsShared] TO [public]
GRANT SELECT ON  [dbo].[pvReportControlsShared] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvReportControlsShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvReportControlsShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvReportControlsShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvReportControlsShared] TO [Viewpoint]
GO
