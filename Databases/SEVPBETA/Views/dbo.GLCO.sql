SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLCO] as select a.* From bGLCO a
GO
GRANT SELECT ON  [dbo].[GLCO] TO [public]
GRANT INSERT ON  [dbo].[GLCO] TO [public]
GRANT DELETE ON  [dbo].[GLCO] TO [public]
GRANT UPDATE ON  [dbo].[GLCO] TO [public]
GO
