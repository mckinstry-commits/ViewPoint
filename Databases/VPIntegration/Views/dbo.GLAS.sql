SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[GLAS] as select a.* From bGLAS a

GO
GRANT SELECT ON  [dbo].[GLAS] TO [public]
GRANT INSERT ON  [dbo].[GLAS] TO [public]
GRANT DELETE ON  [dbo].[GLAS] TO [public]
GRANT UPDATE ON  [dbo].[GLAS] TO [public]
GO
