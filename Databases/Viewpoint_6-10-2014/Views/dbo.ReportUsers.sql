SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.ReportUsers
AS
SELECT     Name, SecurityGroup
FROM         (SELECT     Name, SecurityGroup
                       FROM          (SELECT     VPUserName AS Name, - 1 AS SecurityGroup
                                               FROM          dbo.DDUP
                                               UNION
                                               SELECT     Name, SecurityGroup
                                               FROM         dbo.DDSG
                                               WHERE     (GroupType = 2)) AS derivedtbl_1) AS derivedtbl_2

GO
GRANT SELECT ON  [dbo].[ReportUsers] TO [public]
GRANT INSERT ON  [dbo].[ReportUsers] TO [public]
GRANT DELETE ON  [dbo].[ReportUsers] TO [public]
GRANT UPDATE ON  [dbo].[ReportUsers] TO [public]
GRANT SELECT ON  [dbo].[ReportUsers] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ReportUsers] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ReportUsers] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ReportUsers] TO [Viewpoint]
GO
