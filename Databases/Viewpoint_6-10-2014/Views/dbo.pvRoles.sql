SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[pvRoles]
AS
SELECT     *
FROM         dbo.pRoles


GO
GRANT SELECT ON  [dbo].[pvRoles] TO [public]
GRANT INSERT ON  [dbo].[pvRoles] TO [public]
GRANT DELETE ON  [dbo].[pvRoles] TO [public]
GRANT UPDATE ON  [dbo].[pvRoles] TO [public]
GRANT SELECT ON  [dbo].[pvRoles] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvRoles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvRoles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvRoles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvRoles] TO [Viewpoint]
GO
