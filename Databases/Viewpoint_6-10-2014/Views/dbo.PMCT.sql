SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[PMCT] as select a.* From bPMCT a






GO
GRANT SELECT ON  [dbo].[PMCT] TO [public]
GRANT INSERT ON  [dbo].[PMCT] TO [public]
GRANT DELETE ON  [dbo].[PMCT] TO [public]
GRANT UPDATE ON  [dbo].[PMCT] TO [public]
GRANT SELECT ON  [dbo].[PMCT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMCT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMCT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMCT] TO [Viewpoint]
GO
