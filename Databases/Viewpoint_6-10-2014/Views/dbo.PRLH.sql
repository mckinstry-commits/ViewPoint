SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRLH] as select a.* from bPRLH a 
GO
GRANT SELECT ON  [dbo].[PRLH] TO [public]
GRANT INSERT ON  [dbo].[PRLH] TO [public]
GRANT DELETE ON  [dbo].[PRLH] TO [public]
GRANT UPDATE ON  [dbo].[PRLH] TO [public]
GRANT SELECT ON  [dbo].[PRLH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRLH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRLH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRLH] TO [Viewpoint]
GO