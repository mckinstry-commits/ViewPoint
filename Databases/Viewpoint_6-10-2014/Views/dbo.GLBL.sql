SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLBL] as select a.* From bGLBL a
GO
GRANT SELECT ON  [dbo].[GLBL] TO [public]
GRANT INSERT ON  [dbo].[GLBL] TO [public]
GRANT DELETE ON  [dbo].[GLBL] TO [public]
GRANT UPDATE ON  [dbo].[GLBL] TO [public]
GRANT SELECT ON  [dbo].[GLBL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLBL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLBL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLBL] TO [Viewpoint]
GO
