SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INRO] as select a.* From bINRO a
GO
GRANT SELECT ON  [dbo].[INRO] TO [public]
GRANT INSERT ON  [dbo].[INRO] TO [public]
GRANT DELETE ON  [dbo].[INRO] TO [public]
GRANT UPDATE ON  [dbo].[INRO] TO [public]
GRANT SELECT ON  [dbo].[INRO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INRO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INRO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INRO] TO [Viewpoint]
GO
