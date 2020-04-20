SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCRU] as select a.* From bJCRU a

GO
GRANT SELECT ON  [dbo].[JCRU] TO [public]
GRANT INSERT ON  [dbo].[JCRU] TO [public]
GRANT DELETE ON  [dbo].[JCRU] TO [public]
GRANT UPDATE ON  [dbo].[JCRU] TO [public]
GO
