SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCIN] as select a.* From bJCIN a

GO
GRANT SELECT ON  [dbo].[JCIN] TO [public]
GRANT INSERT ON  [dbo].[JCIN] TO [public]
GRANT DELETE ON  [dbo].[JCIN] TO [public]
GRANT UPDATE ON  [dbo].[JCIN] TO [public]
GO
