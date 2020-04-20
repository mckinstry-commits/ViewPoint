SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udxrefGLDept] as select a.* From budxrefGLDept a
GO
GRANT SELECT ON  [dbo].[udxrefGLDept] TO [public]
GRANT INSERT ON  [dbo].[udxrefGLDept] TO [public]
GRANT DELETE ON  [dbo].[udxrefGLDept] TO [public]
GRANT UPDATE ON  [dbo].[udxrefGLDept] TO [public]
GO
