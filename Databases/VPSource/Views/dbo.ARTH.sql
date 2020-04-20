SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARTH] as select a.* From bARTH a
GO
GRANT SELECT ON  [dbo].[ARTH] TO [public]
GRANT INSERT ON  [dbo].[ARTH] TO [public]
GRANT DELETE ON  [dbo].[ARTH] TO [public]
GRANT UPDATE ON  [dbo].[ARTH] TO [public]
GO
