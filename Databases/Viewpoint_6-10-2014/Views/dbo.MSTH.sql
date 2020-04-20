SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTH] as select a.* From bMSTH a
GO
GRANT SELECT ON  [dbo].[MSTH] TO [public]
GRANT INSERT ON  [dbo].[MSTH] TO [public]
GRANT DELETE ON  [dbo].[MSTH] TO [public]
GRANT UPDATE ON  [dbo].[MSTH] TO [public]
GRANT SELECT ON  [dbo].[MSTH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSTH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSTH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSTH] TO [Viewpoint]
GO
