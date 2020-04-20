SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCTH] as select a.* From bJCTH a
GO
GRANT SELECT ON  [dbo].[JCTH] TO [public]
GRANT INSERT ON  [dbo].[JCTH] TO [public]
GRANT DELETE ON  [dbo].[JCTH] TO [public]
GRANT UPDATE ON  [dbo].[JCTH] TO [public]
GRANT SELECT ON  [dbo].[JCTH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCTH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCTH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCTH] TO [Viewpoint]
GO
