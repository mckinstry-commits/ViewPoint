SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLJB] as select a.* From bGLJB a
GO
GRANT SELECT ON  [dbo].[GLJB] TO [public]
GRANT INSERT ON  [dbo].[GLJB] TO [public]
GRANT DELETE ON  [dbo].[GLJB] TO [public]
GRANT UPDATE ON  [dbo].[GLJB] TO [public]
GRANT SELECT ON  [dbo].[GLJB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLJB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLJB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLJB] TO [Viewpoint]
GO
