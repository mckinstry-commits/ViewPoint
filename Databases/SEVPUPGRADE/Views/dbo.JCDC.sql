SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCDC] as select a.* From bJCDC a

GO
GRANT SELECT ON  [dbo].[JCDC] TO [public]
GRANT INSERT ON  [dbo].[JCDC] TO [public]
GRANT DELETE ON  [dbo].[JCDC] TO [public]
GRANT UPDATE ON  [dbo].[JCDC] TO [public]
GO
