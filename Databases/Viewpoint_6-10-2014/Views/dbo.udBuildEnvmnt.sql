SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udBuildEnvmnt] as select a.* From budBuildEnvmnt a
GO
GRANT SELECT ON  [dbo].[udBuildEnvmnt] TO [public]
GRANT INSERT ON  [dbo].[udBuildEnvmnt] TO [public]
GRANT DELETE ON  [dbo].[udBuildEnvmnt] TO [public]
GRANT UPDATE ON  [dbo].[udBuildEnvmnt] TO [public]
GRANT SELECT ON  [dbo].[udBuildEnvmnt] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udBuildEnvmnt] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udBuildEnvmnt] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udBuildEnvmnt] TO [Viewpoint]
GO
