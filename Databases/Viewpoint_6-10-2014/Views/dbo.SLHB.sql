SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLHB] as select a.* From bSLHB a
GO
GRANT SELECT ON  [dbo].[SLHB] TO [public]
GRANT INSERT ON  [dbo].[SLHB] TO [public]
GRANT DELETE ON  [dbo].[SLHB] TO [public]
GRANT UPDATE ON  [dbo].[SLHB] TO [public]
GRANT SELECT ON  [dbo].[SLHB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLHB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLHB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLHB] TO [Viewpoint]
GO
