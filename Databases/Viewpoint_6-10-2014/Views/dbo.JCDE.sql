SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDE] as select a.* From bJCDE a
GO
GRANT SELECT ON  [dbo].[JCDE] TO [public]
GRANT INSERT ON  [dbo].[JCDE] TO [public]
GRANT DELETE ON  [dbo].[JCDE] TO [public]
GRANT UPDATE ON  [dbo].[JCDE] TO [public]
GRANT SELECT ON  [dbo].[JCDE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCDE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCDE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCDE] TO [Viewpoint]
GO
