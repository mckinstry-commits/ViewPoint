SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCJP] as select a.* From bJCJP a
GO
GRANT SELECT ON  [dbo].[JCJP] TO [public]
GRANT INSERT ON  [dbo].[JCJP] TO [public]
GRANT DELETE ON  [dbo].[JCJP] TO [public]
GRANT UPDATE ON  [dbo].[JCJP] TO [public]
GO
