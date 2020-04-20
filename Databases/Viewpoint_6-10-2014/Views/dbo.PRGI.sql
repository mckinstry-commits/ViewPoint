SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGI] as select a.* From bPRGI a
GO
GRANT SELECT ON  [dbo].[PRGI] TO [public]
GRANT INSERT ON  [dbo].[PRGI] TO [public]
GRANT DELETE ON  [dbo].[PRGI] TO [public]
GRANT UPDATE ON  [dbo].[PRGI] TO [public]
GRANT SELECT ON  [dbo].[PRGI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRGI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRGI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRGI] TO [Viewpoint]
GO
