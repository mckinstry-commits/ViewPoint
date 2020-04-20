SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCTE] as select a.* From bJCTE a
GO
GRANT SELECT ON  [dbo].[JCTE] TO [public]
GRANT INSERT ON  [dbo].[JCTE] TO [public]
GRANT DELETE ON  [dbo].[JCTE] TO [public]
GRANT UPDATE ON  [dbo].[JCTE] TO [public]
GRANT SELECT ON  [dbo].[JCTE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCTE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCTE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCTE] TO [Viewpoint]
GO
