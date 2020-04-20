SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCOP] as select a.* From bJCOP a
GO
GRANT SELECT ON  [dbo].[JCOP] TO [public]
GRANT INSERT ON  [dbo].[JCOP] TO [public]
GRANT DELETE ON  [dbo].[JCOP] TO [public]
GRANT UPDATE ON  [dbo].[JCOP] TO [public]
GO
