SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLJR] as select a.* From bGLJR a
GO
GRANT SELECT ON  [dbo].[GLJR] TO [public]
GRANT INSERT ON  [dbo].[GLJR] TO [public]
GRANT DELETE ON  [dbo].[GLJR] TO [public]
GRANT UPDATE ON  [dbo].[GLJR] TO [public]
GO
