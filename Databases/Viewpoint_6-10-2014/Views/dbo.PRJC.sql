SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRJC] as select a.* from bPRJC a 
GO
GRANT SELECT ON  [dbo].[PRJC] TO [public]
GRANT INSERT ON  [dbo].[PRJC] TO [public]
GRANT DELETE ON  [dbo].[PRJC] TO [public]
GRANT UPDATE ON  [dbo].[PRJC] TO [public]
GRANT SELECT ON  [dbo].[PRJC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRJC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRJC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRJC] TO [Viewpoint]
GO