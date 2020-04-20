SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLAJ] as select a.* From bGLAJ a
GO
GRANT SELECT ON  [dbo].[GLAJ] TO [public]
GRANT INSERT ON  [dbo].[GLAJ] TO [public]
GRANT DELETE ON  [dbo].[GLAJ] TO [public]
GRANT UPDATE ON  [dbo].[GLAJ] TO [public]
GRANT SELECT ON  [dbo].[GLAJ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLAJ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLAJ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLAJ] TO [Viewpoint]
GO
