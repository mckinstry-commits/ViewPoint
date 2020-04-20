SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRRO] as select a.* From bPRRO a
GO
GRANT SELECT ON  [dbo].[PRRO] TO [public]
GRANT INSERT ON  [dbo].[PRRO] TO [public]
GRANT DELETE ON  [dbo].[PRRO] TO [public]
GRANT UPDATE ON  [dbo].[PRRO] TO [public]
GO
