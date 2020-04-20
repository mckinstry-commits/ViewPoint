SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCJR] as select a.* From bJCJR a
GO
GRANT SELECT ON  [dbo].[JCJR] TO [public]
GRANT INSERT ON  [dbo].[JCJR] TO [public]
GRANT DELETE ON  [dbo].[JCJR] TO [public]
GRANT UPDATE ON  [dbo].[JCJR] TO [public]
GRANT SELECT ON  [dbo].[JCJR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJR] TO [Viewpoint]
GO
