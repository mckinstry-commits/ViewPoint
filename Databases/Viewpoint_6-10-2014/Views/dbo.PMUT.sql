SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUT] as select a.* From bPMUT a

GO
GRANT SELECT ON  [dbo].[PMUT] TO [public]
GRANT INSERT ON  [dbo].[PMUT] TO [public]
GRANT DELETE ON  [dbo].[PMUT] TO [public]
GRANT UPDATE ON  [dbo].[PMUT] TO [public]
GRANT SELECT ON  [dbo].[PMUT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMUT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMUT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMUT] TO [Viewpoint]
GO
