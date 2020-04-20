SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLBR] as select a.* From bGLBR a
GO
GRANT SELECT ON  [dbo].[GLBR] TO [public]
GRANT INSERT ON  [dbo].[GLBR] TO [public]
GRANT DELETE ON  [dbo].[GLBR] TO [public]
GRANT UPDATE ON  [dbo].[GLBR] TO [public]
GRANT SELECT ON  [dbo].[GLBR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLBR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLBR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLBR] TO [Viewpoint]
GO
