SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCAC] as select a.* From bJCAC a
GO
GRANT SELECT ON  [dbo].[JCAC] TO [public]
GRANT INSERT ON  [dbo].[JCAC] TO [public]
GRANT DELETE ON  [dbo].[JCAC] TO [public]
GRANT UPDATE ON  [dbo].[JCAC] TO [public]
GRANT SELECT ON  [dbo].[JCAC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCAC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCAC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCAC] TO [Viewpoint]
GO
