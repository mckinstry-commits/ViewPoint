SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREC] as select a.* From bPREC a
GO
GRANT SELECT ON  [dbo].[PREC] TO [public]
GRANT INSERT ON  [dbo].[PREC] TO [public]
GRANT DELETE ON  [dbo].[PREC] TO [public]
GRANT UPDATE ON  [dbo].[PREC] TO [public]
GO
