SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create view [dbo].[HQRoleMemberOverride] as select a.* from dbo.vHQRoleMemberOverride a





GO
GRANT SELECT ON  [dbo].[HQRoleMemberOverride] TO [public]
GRANT INSERT ON  [dbo].[HQRoleMemberOverride] TO [public]
GRANT DELETE ON  [dbo].[HQRoleMemberOverride] TO [public]
GRANT UPDATE ON  [dbo].[HQRoleMemberOverride] TO [public]
GO
