SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRWE] as select a.* from bPRWE a 
GO
GRANT SELECT ON  [dbo].[PRWE] TO [public]
GRANT INSERT ON  [dbo].[PRWE] TO [public]
GRANT DELETE ON  [dbo].[PRWE] TO [public]
GRANT UPDATE ON  [dbo].[PRWE] TO [public]
GRANT SELECT ON  [dbo].[PRWE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRWE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRWE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRWE] TO [Viewpoint]
GO