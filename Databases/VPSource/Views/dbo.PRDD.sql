SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDD] as select a.* from bPRDD a 
GO
GRANT SELECT ON  [dbo].[PRDD] TO [public]
GRANT INSERT ON  [dbo].[PRDD] TO [public]
GRANT DELETE ON  [dbo].[PRDD] TO [public]
GRANT UPDATE ON  [dbo].[PRDD] TO [public]
GO