SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLAC] as select a.* From bGLAC a
GO
GRANT SELECT ON  [dbo].[GLAC] TO [public]
GRANT INSERT ON  [dbo].[GLAC] TO [public]
GRANT DELETE ON  [dbo].[GLAC] TO [public]
GRANT UPDATE ON  [dbo].[GLAC] TO [public]
GO
