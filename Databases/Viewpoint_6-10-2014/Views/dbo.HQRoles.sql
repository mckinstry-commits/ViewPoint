SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[HQRoles] as select a.* From vHQRoles a





GO
GRANT SELECT ON  [dbo].[HQRoles] TO [public]
GRANT INSERT ON  [dbo].[HQRoles] TO [public]
GRANT DELETE ON  [dbo].[HQRoles] TO [public]
GRANT UPDATE ON  [dbo].[HQRoles] TO [public]
GRANT SELECT ON  [dbo].[HQRoles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQRoles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQRoles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQRoles] TO [Viewpoint]
GO
