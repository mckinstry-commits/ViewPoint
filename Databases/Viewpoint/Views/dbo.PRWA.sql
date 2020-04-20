SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWA] as select a.* from bPRWA a 
GO
GRANT SELECT ON  [dbo].[PRWA] TO [public]
GRANT INSERT ON  [dbo].[PRWA] TO [public]
GRANT DELETE ON  [dbo].[PRWA] TO [public]
GRANT UPDATE ON  [dbo].[PRWA] TO [public]
GO