SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWL] as select a.* from bPRWL a 
GO
GRANT SELECT ON  [dbo].[PRWL] TO [public]
GRANT INSERT ON  [dbo].[PRWL] TO [public]
GRANT DELETE ON  [dbo].[PRWL] TO [public]
GRANT UPDATE ON  [dbo].[PRWL] TO [public]
GO