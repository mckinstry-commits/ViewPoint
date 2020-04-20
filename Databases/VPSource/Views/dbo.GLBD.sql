SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLBD] as select a.* From bGLBD a
GO
GRANT SELECT ON  [dbo].[GLBD] TO [public]
GRANT INSERT ON  [dbo].[GLBD] TO [public]
GRANT DELETE ON  [dbo].[GLBD] TO [public]
GRANT UPDATE ON  [dbo].[GLBD] TO [public]
GO
