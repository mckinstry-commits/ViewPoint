SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLHD] as select a.* From bSLHD a
GO
GRANT SELECT ON  [dbo].[SLHD] TO [public]
GRANT INSERT ON  [dbo].[SLHD] TO [public]
GRANT DELETE ON  [dbo].[SLHD] TO [public]
GRANT UPDATE ON  [dbo].[SLHD] TO [public]
GRANT SELECT ON  [dbo].[SLHD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLHD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLHD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLHD] TO [Viewpoint]
GO
