SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRH] as select a.* From bPRRH a
GO
GRANT SELECT ON  [dbo].[PRRH] TO [public]
GRANT INSERT ON  [dbo].[PRRH] TO [public]
GRANT DELETE ON  [dbo].[PRRH] TO [public]
GRANT UPDATE ON  [dbo].[PRRH] TO [public]
GO
