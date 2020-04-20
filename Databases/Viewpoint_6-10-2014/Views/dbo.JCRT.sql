SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCRT] as select a.* From bJCRT a

GO
GRANT SELECT ON  [dbo].[JCRT] TO [public]
GRANT INSERT ON  [dbo].[JCRT] TO [public]
GRANT DELETE ON  [dbo].[JCRT] TO [public]
GRANT UPDATE ON  [dbo].[JCRT] TO [public]
GRANT SELECT ON  [dbo].[JCRT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCRT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCRT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCRT] TO [Viewpoint]
GO
