SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLFY] as select a.* From bGLFY a
GO
GRANT SELECT ON  [dbo].[GLFY] TO [public]
GRANT INSERT ON  [dbo].[GLFY] TO [public]
GRANT DELETE ON  [dbo].[GLFY] TO [public]
GRANT UPDATE ON  [dbo].[GLFY] TO [public]
GO
