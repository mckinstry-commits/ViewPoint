SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[HQRoleMember] as select a.* from dbo.vHQRoleMember a

GO
GRANT SELECT ON  [dbo].[HQRoleMember] TO [public]
GRANT INSERT ON  [dbo].[HQRoleMember] TO [public]
GRANT DELETE ON  [dbo].[HQRoleMember] TO [public]
GRANT UPDATE ON  [dbo].[HQRoleMember] TO [public]
GRANT SELECT ON  [dbo].[HQRoleMember] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQRoleMember] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQRoleMember] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQRoleMember] TO [Viewpoint]
GO
