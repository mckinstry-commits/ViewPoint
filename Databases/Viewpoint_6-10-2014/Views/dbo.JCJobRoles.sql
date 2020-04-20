SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCJobRoles] as select a.* From vJCJobRoles a
GO
GRANT SELECT ON  [dbo].[JCJobRoles] TO [public]
GRANT INSERT ON  [dbo].[JCJobRoles] TO [public]
GRANT DELETE ON  [dbo].[JCJobRoles] TO [public]
GRANT UPDATE ON  [dbo].[JCJobRoles] TO [public]
GRANT SELECT ON  [dbo].[JCJobRoles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJobRoles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJobRoles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJobRoles] TO [Viewpoint]
GO
