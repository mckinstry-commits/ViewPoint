SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGL] as select a.* from bPRGL a 
GO
GRANT SELECT ON  [dbo].[PRGL] TO [public]
GRANT INSERT ON  [dbo].[PRGL] TO [public]
GRANT DELETE ON  [dbo].[PRGL] TO [public]
GRANT UPDATE ON  [dbo].[PRGL] TO [public]
GRANT SELECT ON  [dbo].[PRGL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRGL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRGL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRGL] TO [Viewpoint]
GO