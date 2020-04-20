SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCIB] as select a.* From bJCIB a
GO
GRANT SELECT ON  [dbo].[JCIB] TO [public]
GRANT INSERT ON  [dbo].[JCIB] TO [public]
GRANT DELETE ON  [dbo].[JCIB] TO [public]
GRANT UPDATE ON  [dbo].[JCIB] TO [public]
GRANT SELECT ON  [dbo].[JCIB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCIB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCIB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCIB] TO [Viewpoint]
GO
