SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOC] as select a.* From bPMOC a
GO
GRANT SELECT ON  [dbo].[PMOC] TO [public]
GRANT INSERT ON  [dbo].[PMOC] TO [public]
GRANT DELETE ON  [dbo].[PMOC] TO [public]
GRANT UPDATE ON  [dbo].[PMOC] TO [public]
GRANT SELECT ON  [dbo].[PMOC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOC] TO [Viewpoint]
GO
