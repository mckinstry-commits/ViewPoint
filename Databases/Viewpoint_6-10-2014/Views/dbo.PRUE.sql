SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRUE] as select a.* from bPRUE a 
GO
GRANT SELECT ON  [dbo].[PRUE] TO [public]
GRANT INSERT ON  [dbo].[PRUE] TO [public]
GRANT DELETE ON  [dbo].[PRUE] TO [public]
GRANT UPDATE ON  [dbo].[PRUE] TO [public]
GRANT SELECT ON  [dbo].[PRUE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRUE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRUE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRUE] TO [Viewpoint]
GO