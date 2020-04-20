SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PREL] as select a.* from bPREL a 
GO
GRANT SELECT ON  [dbo].[PREL] TO [public]
GRANT INSERT ON  [dbo].[PREL] TO [public]
GRANT DELETE ON  [dbo].[PREL] TO [public]
GRANT UPDATE ON  [dbo].[PREL] TO [public]
GRANT SELECT ON  [dbo].[PREL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PREL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PREL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PREL] TO [Viewpoint]
GO