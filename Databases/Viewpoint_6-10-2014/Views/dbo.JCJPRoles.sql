SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCJPRoles] as select a.* From vJCJPRoles a
GO
GRANT SELECT ON  [dbo].[JCJPRoles] TO [public]
GRANT INSERT ON  [dbo].[JCJPRoles] TO [public]
GRANT DELETE ON  [dbo].[JCJPRoles] TO [public]
GRANT UPDATE ON  [dbo].[JCJPRoles] TO [public]
GRANT SELECT ON  [dbo].[JCJPRoles] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJPRoles] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJPRoles] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJPRoles] TO [Viewpoint]
GO
