SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLDB] as select a.* From bGLDB a
GO
GRANT SELECT ON  [dbo].[GLDB] TO [public]
GRANT INSERT ON  [dbo].[GLDB] TO [public]
GRANT DELETE ON  [dbo].[GLDB] TO [public]
GRANT UPDATE ON  [dbo].[GLDB] TO [public]
GRANT SELECT ON  [dbo].[GLDB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLDB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLDB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLDB] TO [Viewpoint]
GO
