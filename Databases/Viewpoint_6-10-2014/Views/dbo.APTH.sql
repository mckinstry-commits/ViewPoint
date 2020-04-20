SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APTH] as select a.* From bAPTH a
GO
GRANT SELECT ON  [dbo].[APTH] TO [public]
GRANT INSERT ON  [dbo].[APTH] TO [public]
GRANT DELETE ON  [dbo].[APTH] TO [public]
GRANT UPDATE ON  [dbo].[APTH] TO [public]
GRANT SELECT ON  [dbo].[APTH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APTH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APTH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APTH] TO [Viewpoint]
GO
