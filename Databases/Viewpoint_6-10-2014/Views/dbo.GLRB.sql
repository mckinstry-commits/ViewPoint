SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLRB] as select a.* From bGLRB a
GO
GRANT SELECT ON  [dbo].[GLRB] TO [public]
GRANT INSERT ON  [dbo].[GLRB] TO [public]
GRANT DELETE ON  [dbo].[GLRB] TO [public]
GRANT UPDATE ON  [dbo].[GLRB] TO [public]
GRANT SELECT ON  [dbo].[GLRB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLRB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLRB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLRB] TO [Viewpoint]
GO
