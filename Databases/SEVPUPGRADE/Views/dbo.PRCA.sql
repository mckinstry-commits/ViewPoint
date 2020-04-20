SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCA] as select a.* from bPRCA a 
GO
GRANT SELECT ON  [dbo].[PRCA] TO [public]
GRANT INSERT ON  [dbo].[PRCA] TO [public]
GRANT DELETE ON  [dbo].[PRCA] TO [public]
GRANT UPDATE ON  [dbo].[PRCA] TO [public]
GO