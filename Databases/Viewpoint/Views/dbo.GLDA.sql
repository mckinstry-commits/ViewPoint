SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLDA] as select a.* From bGLDA a

GO
GRANT SELECT ON  [dbo].[GLDA] TO [public]
GRANT INSERT ON  [dbo].[GLDA] TO [public]
GRANT DELETE ON  [dbo].[GLDA] TO [public]
GRANT UPDATE ON  [dbo].[GLDA] TO [public]
GO
