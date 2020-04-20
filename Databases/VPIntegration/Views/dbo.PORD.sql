SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORD] as select a.* From bPORD a
GO
GRANT SELECT ON  [dbo].[PORD] TO [public]
GRANT INSERT ON  [dbo].[PORD] TO [public]
GRANT DELETE ON  [dbo].[PORD] TO [public]
GRANT UPDATE ON  [dbo].[PORD] TO [public]
GO
