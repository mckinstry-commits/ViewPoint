SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspReportSecurityGet]
(@ReportID int, @UserID int, @RoleID int = null )
AS
	
SET NOCOUNT ON;

SELECT DISTINCT r.RoleID, r.Name, @ReportID as ReportID, 
CASE ISNULL(s.Access, -1) WHEN -1 THEN 0 ELSE s.Access END as Access,
CASE ISNULL(s.Access, -1) 
	WHEN -1 THEN 'None'
	WHEN 0 THEN 'None'
	WHEN 1 THEN 'Parameters Required'
	WHEN 2 THEN 'Full Access'
	ELSE 'None'
	END
	as 'AccessDisplay'
,@UserID as 'UserID'
FROM pRoles r LEFT OUTER JOIN
pvReportSecurityShared s ON r.RoleID = s.RoleID AND (s.ReportID = @ReportID OR s.ReportID IS NULL)
WHERE 
r.RoleID NOT IN (0, 1, 42)
AND r.RoleID = ISNULL(@RoleID, r.RoleID)


GO
GRANT EXECUTE ON  [dbo].[vpspReportSecurityGet] TO [VCSPortal]
GO
