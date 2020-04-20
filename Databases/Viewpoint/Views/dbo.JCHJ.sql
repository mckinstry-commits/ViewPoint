SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCHJ] as select a.* From bJCHJ a

GO
GRANT SELECT ON  [dbo].[JCHJ] TO [public]
GRANT INSERT ON  [dbo].[JCHJ] TO [public]
GRANT DELETE ON  [dbo].[JCHJ] TO [public]
GRANT UPDATE ON  [dbo].[JCHJ] TO [public]
GO
