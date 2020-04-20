SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRSP] as select a.* from bPRSP a 
GO
GRANT SELECT ON  [dbo].[PRSP] TO [public]
GRANT INSERT ON  [dbo].[PRSP] TO [public]
GRANT DELETE ON  [dbo].[PRSP] TO [public]
GRANT UPDATE ON  [dbo].[PRSP] TO [public]
GO