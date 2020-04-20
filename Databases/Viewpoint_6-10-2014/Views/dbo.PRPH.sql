SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRPH] as select a.* from bPRPH a 
GO
GRANT SELECT ON  [dbo].[PRPH] TO [public]
GRANT INSERT ON  [dbo].[PRPH] TO [public]
GRANT DELETE ON  [dbo].[PRPH] TO [public]
GRANT UPDATE ON  [dbo].[PRPH] TO [public]
GRANT SELECT ON  [dbo].[PRPH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRPH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRPH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRPH] TO [Viewpoint]
GO