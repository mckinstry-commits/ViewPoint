SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PortalUsers] as select a.* From pUsers a

GO
GRANT SELECT ON  [dbo].[PortalUsers] TO [public]
GRANT INSERT ON  [dbo].[PortalUsers] TO [public]
GRANT DELETE ON  [dbo].[PortalUsers] TO [public]
GRANT UPDATE ON  [dbo].[PortalUsers] TO [public]
GRANT SELECT ON  [dbo].[PortalUsers] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PortalUsers] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PortalUsers] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PortalUsers] TO [Viewpoint]
GO
