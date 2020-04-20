SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCCP] as select a.* From bJCCP a
GO
GRANT SELECT ON  [dbo].[JCCP] TO [public]
GRANT INSERT ON  [dbo].[JCCP] TO [public]
GRANT DELETE ON  [dbo].[JCCP] TO [public]
GRANT UPDATE ON  [dbo].[JCCP] TO [public]
GRANT SELECT ON  [dbo].[JCCP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCP] TO [Viewpoint]
GO
