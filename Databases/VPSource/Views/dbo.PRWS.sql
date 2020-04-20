SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWS] as select a.* from bPRWS a 
GO
GRANT SELECT ON  [dbo].[PRWS] TO [public]
GRANT INSERT ON  [dbo].[PRWS] TO [public]
GRANT DELETE ON  [dbo].[PRWS] TO [public]
GRANT UPDATE ON  [dbo].[PRWS] TO [public]
GO