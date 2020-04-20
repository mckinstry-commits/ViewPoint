SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[pvReportPortalControlAccess]
AS

	SELECT 0 AS KeyField, 'Not Available' AS 'AccessDescription'
	UNION
	SELECT 1 AS KeyField, 'Available' AS 'AccessDescription'
GO
GRANT SELECT ON  [dbo].[pvReportPortalControlAccess] TO [public]
GRANT INSERT ON  [dbo].[pvReportPortalControlAccess] TO [public]
GRANT DELETE ON  [dbo].[pvReportPortalControlAccess] TO [public]
GRANT UPDATE ON  [dbo].[pvReportPortalControlAccess] TO [public]
GRANT SELECT ON  [dbo].[pvReportPortalControlAccess] TO [VCSPortal]
GO
