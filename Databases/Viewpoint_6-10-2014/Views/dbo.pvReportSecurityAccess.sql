SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[pvReportSecurityAccess]
AS

	SELECT 0 AS KeyField, 'None' AS 'AccessDescription'
	UNION
	--We don't need this anymore
	--SELECT 1 AS KeyField, 'Parameters Required' AS 'AccessDescription'
	--UNION
	SELECT 2 As KeyField, 'Full Access' AS 'AccessDescription'

GO
GRANT SELECT ON  [dbo].[pvReportSecurityAccess] TO [public]
GRANT INSERT ON  [dbo].[pvReportSecurityAccess] TO [public]
GRANT DELETE ON  [dbo].[pvReportSecurityAccess] TO [public]
GRANT UPDATE ON  [dbo].[pvReportSecurityAccess] TO [public]
GRANT SELECT ON  [dbo].[pvReportSecurityAccess] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvReportSecurityAccess] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvReportSecurityAccess] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvReportSecurityAccess] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvReportSecurityAccess] TO [Viewpoint]
GO
