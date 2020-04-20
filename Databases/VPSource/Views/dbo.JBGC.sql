SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBGC] as select a.* From bJBGC a

GO
GRANT SELECT ON  [dbo].[JBGC] TO [public]
GRANT INSERT ON  [dbo].[JBGC] TO [public]
GRANT DELETE ON  [dbo].[JBGC] TO [public]
GRANT UPDATE ON  [dbo].[JBGC] TO [public]
GO
