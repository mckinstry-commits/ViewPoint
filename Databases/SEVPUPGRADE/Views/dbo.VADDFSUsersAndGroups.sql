SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VADDFSUsersAndGroups
AS
SELECT     Name, SecurityGroup
FROM         (SELECT     Name, SecurityGroup
                       FROM          (SELECT     VPUserName AS Name, - 1 AS SecurityGroup
                                               FROM          dbo.DDUP
                                               UNION
                                               SELECT     Name, SecurityGroup
                                               FROM         dbo.DDSG
                                               WHERE     (GroupType = 1)) AS derivedtbl_1) AS derivedtbl_2


GO
GRANT SELECT ON  [dbo].[VADDFSUsersAndGroups] TO [public]
GRANT INSERT ON  [dbo].[VADDFSUsersAndGroups] TO [public]
GRANT DELETE ON  [dbo].[VADDFSUsersAndGroups] TO [public]
GRANT UPDATE ON  [dbo].[VADDFSUsersAndGroups] TO [public]
GO
