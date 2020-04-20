SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VPQuerySecurity] as select a.* From vVPQuerySecurity a
GO
GRANT SELECT ON  [dbo].[VPQuerySecurity] TO [public]
GRANT INSERT ON  [dbo].[VPQuerySecurity] TO [public]
GRANT DELETE ON  [dbo].[VPQuerySecurity] TO [public]
GRANT UPDATE ON  [dbo].[VPQuerySecurity] TO [public]
GO
