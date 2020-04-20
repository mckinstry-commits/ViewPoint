SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDS] as select a.* from bPRDS a 
GO
GRANT SELECT ON  [dbo].[PRDS] TO [public]
GRANT INSERT ON  [dbo].[PRDS] TO [public]
GRANT DELETE ON  [dbo].[PRDS] TO [public]
GRANT UPDATE ON  [dbo].[PRDS] TO [public]
GRANT SELECT ON  [dbo].[PRDS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRDS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRDS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRDS] TO [Viewpoint]
GO