SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCAJ] as select a.* From bJCAJ a

GO
GRANT SELECT ON  [dbo].[JCAJ] TO [public]
GRANT INSERT ON  [dbo].[JCAJ] TO [public]
GRANT DELETE ON  [dbo].[JCAJ] TO [public]
GRANT UPDATE ON  [dbo].[JCAJ] TO [public]
GO
