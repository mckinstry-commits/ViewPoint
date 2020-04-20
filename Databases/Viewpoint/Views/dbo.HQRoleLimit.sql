SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



create view [dbo].[HQRoleLimit] as select a.* from dbo.vHQRoleLimit a



GO
GRANT SELECT ON  [dbo].[HQRoleLimit] TO [public]
GRANT INSERT ON  [dbo].[HQRoleLimit] TO [public]
GRANT DELETE ON  [dbo].[HQRoleLimit] TO [public]
GRANT UPDATE ON  [dbo].[HQRoleLimit] TO [public]
GO
