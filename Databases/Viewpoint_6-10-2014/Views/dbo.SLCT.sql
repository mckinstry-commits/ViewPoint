SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLCT] as select a.* From bSLCT a
GO
GRANT SELECT ON  [dbo].[SLCT] TO [public]
GRANT INSERT ON  [dbo].[SLCT] TO [public]
GRANT DELETE ON  [dbo].[SLCT] TO [public]
GRANT UPDATE ON  [dbo].[SLCT] TO [public]
GRANT SELECT ON  [dbo].[SLCT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLCT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLCT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLCT] TO [Viewpoint]
GO
