SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRPE] as select a.* From bPRPE a

GO
GRANT SELECT ON  [dbo].[PRPE] TO [public]
GRANT INSERT ON  [dbo].[PRPE] TO [public]
GRANT DELETE ON  [dbo].[PRPE] TO [public]
GRANT UPDATE ON  [dbo].[PRPE] TO [public]
GO
