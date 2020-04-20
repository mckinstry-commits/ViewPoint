SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMCA] as select a.* From bPMCA a
GO
GRANT SELECT ON  [dbo].[PMCA] TO [public]
GRANT INSERT ON  [dbo].[PMCA] TO [public]
GRANT DELETE ON  [dbo].[PMCA] TO [public]
GRANT UPDATE ON  [dbo].[PMCA] TO [public]
GRANT SELECT ON  [dbo].[PMCA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCA] TO [Viewpoint]
GO
