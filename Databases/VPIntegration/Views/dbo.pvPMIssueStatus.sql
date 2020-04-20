SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMIssueStatus
AS
SELECT     0 AS KeyField, 'Open' AS StatusText, NULL AS 'DateResolved'
UNION
SELECT     1 AS KeyField, 'Closed' AS StatusText, GETDATE() AS 'DateResolved'


GO
GRANT SELECT ON  [dbo].[pvPMIssueStatus] TO [public]
GRANT INSERT ON  [dbo].[pvPMIssueStatus] TO [public]
GRANT DELETE ON  [dbo].[pvPMIssueStatus] TO [public]
GRANT UPDATE ON  [dbo].[pvPMIssueStatus] TO [public]
GRANT SELECT ON  [dbo].[pvPMIssueStatus] TO [VCSPortal]
GO
