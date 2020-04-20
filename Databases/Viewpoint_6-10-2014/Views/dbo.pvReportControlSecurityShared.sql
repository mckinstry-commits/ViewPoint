SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[pvReportControlSecurityShared] AS

SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
	ISNULL(c.PortalControlID, t.PortalControlID) AS PortalControlID,
	ISNULL(c.RoleID, t.RoleID) AS RoleID,
	ISNULL(c.Access, t.Access) AS Access
FROM dbo.pReportPortalControlSecurityCustom AS c
FULL OUTER JOIN dbo.pReportPortalControlSecurity AS t 
ON t.ReportID = c.ReportID AND t.PortalControlID = c.PortalControlID
AND t.RoleID = c.RoleID
GO
GRANT SELECT ON  [dbo].[pvReportControlSecurityShared] TO [public]
GRANT INSERT ON  [dbo].[pvReportControlSecurityShared] TO [public]
GRANT DELETE ON  [dbo].[pvReportControlSecurityShared] TO [public]
GRANT UPDATE ON  [dbo].[pvReportControlSecurityShared] TO [public]
GRANT SELECT ON  [dbo].[pvReportControlSecurityShared] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvReportControlSecurityShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvReportControlSecurityShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvReportControlSecurityShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvReportControlSecurityShared] TO [Viewpoint]
GO
