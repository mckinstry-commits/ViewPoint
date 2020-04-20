SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOD] as select a.* From bJCOD a
GO
GRANT SELECT ON  [dbo].[JCOD] TO [public]
GRANT INSERT ON  [dbo].[JCOD] TO [public]
GRANT DELETE ON  [dbo].[JCOD] TO [public]
GRANT UPDATE ON  [dbo].[JCOD] TO [public]
GRANT SELECT ON  [dbo].[JCOD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCOD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCOD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCOD] TO [Viewpoint]
GO
