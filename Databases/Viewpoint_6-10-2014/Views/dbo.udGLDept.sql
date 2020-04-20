SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udGLDept] as select a.* From budGLDept a
GO
GRANT SELECT ON  [dbo].[udGLDept] TO [public]
GRANT INSERT ON  [dbo].[udGLDept] TO [public]
GRANT DELETE ON  [dbo].[udGLDept] TO [public]
GRANT UPDATE ON  [dbo].[udGLDept] TO [public]
GO
