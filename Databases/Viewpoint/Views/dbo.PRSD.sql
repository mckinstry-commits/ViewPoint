SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSD] as select a.* From bPRSD a

GO
GRANT SELECT ON  [dbo].[PRSD] TO [public]
GRANT INSERT ON  [dbo].[PRSD] TO [public]
GRANT DELETE ON  [dbo].[PRSD] TO [public]
GRANT UPDATE ON  [dbo].[PRSD] TO [public]
GO
