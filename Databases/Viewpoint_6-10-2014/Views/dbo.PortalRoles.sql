SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- Build View for Validation
CREATE view [dbo].[PortalRoles] as 
select * from pRoles with (nolock)where RoleID > 1 and RoleID <> 42 and Active = 1

GO
GRANT SELECT ON  [dbo].[PortalRoles] TO [public]
GRANT INSERT ON  [dbo].[PortalRoles] TO [public]
GRANT DELETE ON  [dbo].[PortalRoles] TO [public]
GRANT UPDATE ON  [dbo].[PortalRoles] TO [public]
GRANT SELECT ON  [dbo].[PortalRoles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PortalRoles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PortalRoles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PortalRoles] TO [Viewpoint]
GO
