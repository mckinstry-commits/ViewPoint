SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplaySecurityGroups
AS
SELECT     KeyID, DisplayID, SecurityGroup
FROM         dbo.vVPDisplaySecurityGroups

GO
GRANT SELECT ON  [dbo].[VPDisplaySecurityGroups] TO [public]
GRANT INSERT ON  [dbo].[VPDisplaySecurityGroups] TO [public]
GRANT DELETE ON  [dbo].[VPDisplaySecurityGroups] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplaySecurityGroups] TO [public]
GRANT SELECT ON  [dbo].[VPDisplaySecurityGroups] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPDisplaySecurityGroups] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPDisplaySecurityGroups] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPDisplaySecurityGroups] TO [Viewpoint]
GO
