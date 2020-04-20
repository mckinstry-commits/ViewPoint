SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTH] as select a.* from bPRTH a 
GO
GRANT SELECT ON  [dbo].[PRTH] TO [public]
GRANT INSERT ON  [dbo].[PRTH] TO [public]
GRANT DELETE ON  [dbo].[PRTH] TO [public]
GRANT UPDATE ON  [dbo].[PRTH] TO [public]
GO