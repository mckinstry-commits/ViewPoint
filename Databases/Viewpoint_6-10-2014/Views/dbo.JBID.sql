SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBID] as select a.* From bJBID a
GO
GRANT SELECT ON  [dbo].[JBID] TO [public]
GRANT INSERT ON  [dbo].[JBID] TO [public]
GRANT DELETE ON  [dbo].[JBID] TO [public]
GRANT UPDATE ON  [dbo].[JBID] TO [public]
GRANT SELECT ON  [dbo].[JBID] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBID] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBID] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBID] TO [Viewpoint]
GO
