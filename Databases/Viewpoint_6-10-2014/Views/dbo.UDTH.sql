SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[UDTH] as select a.* From bUDTH a
GO
GRANT SELECT ON  [dbo].[UDTH] TO [public]
GRANT INSERT ON  [dbo].[UDTH] TO [public]
GRANT DELETE ON  [dbo].[UDTH] TO [public]
GRANT UPDATE ON  [dbo].[UDTH] TO [public]
GRANT SELECT ON  [dbo].[UDTH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[UDTH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[UDTH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[UDTH] TO [Viewpoint]
GO
