SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE view [dbo].[PMCU] as select a.* From bPMCU a









GO
GRANT SELECT ON  [dbo].[PMCU] TO [public]
GRANT INSERT ON  [dbo].[PMCU] TO [public]
GRANT DELETE ON  [dbo].[PMCU] TO [public]
GRANT UPDATE ON  [dbo].[PMCU] TO [public]
GRANT SELECT ON  [dbo].[PMCU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCU] TO [Viewpoint]
GO
