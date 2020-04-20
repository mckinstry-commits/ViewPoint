SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLYB] as select a.* From bGLYB a
GO
GRANT SELECT ON  [dbo].[GLYB] TO [public]
GRANT INSERT ON  [dbo].[GLYB] TO [public]
GRANT DELETE ON  [dbo].[GLYB] TO [public]
GRANT UPDATE ON  [dbo].[GLYB] TO [public]
GRANT SELECT ON  [dbo].[GLYB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLYB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLYB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLYB] TO [Viewpoint]
GO
