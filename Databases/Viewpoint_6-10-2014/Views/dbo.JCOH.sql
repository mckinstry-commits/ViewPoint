SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOH] as select a.* From bJCOH a
GO
GRANT SELECT ON  [dbo].[JCOH] TO [public]
GRANT INSERT ON  [dbo].[JCOH] TO [public]
GRANT DELETE ON  [dbo].[JCOH] TO [public]
GRANT UPDATE ON  [dbo].[JCOH] TO [public]
GRANT SELECT ON  [dbo].[JCOH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCOH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCOH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCOH] TO [Viewpoint]
GO
