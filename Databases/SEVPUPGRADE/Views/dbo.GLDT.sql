SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLDT] as select a.* From bGLDT a
GO
GRANT SELECT ON  [dbo].[GLDT] TO [public]
GRANT INSERT ON  [dbo].[GLDT] TO [public]
GRANT DELETE ON  [dbo].[GLDT] TO [public]
GRANT UPDATE ON  [dbo].[GLDT] TO [public]
GO
