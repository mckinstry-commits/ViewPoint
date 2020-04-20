SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDA] as select a.* From bJCDA a
GO
GRANT SELECT ON  [dbo].[JCDA] TO [public]
GRANT INSERT ON  [dbo].[JCDA] TO [public]
GRANT DELETE ON  [dbo].[JCDA] TO [public]
GRANT UPDATE ON  [dbo].[JCDA] TO [public]
GRANT SELECT ON  [dbo].[JCDA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCDA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCDA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCDA] TO [Viewpoint]
GO
