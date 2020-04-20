SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLPD] as select a.* From bGLPD a
GO
GRANT SELECT ON  [dbo].[GLPD] TO [public]
GRANT INSERT ON  [dbo].[GLPD] TO [public]
GRANT DELETE ON  [dbo].[GLPD] TO [public]
GRANT UPDATE ON  [dbo].[GLPD] TO [public]
GRANT SELECT ON  [dbo].[GLPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLPD] TO [Viewpoint]
GO
