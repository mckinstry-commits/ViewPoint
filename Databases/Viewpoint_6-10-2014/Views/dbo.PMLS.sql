SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE view [dbo].[PMLS] as select a.* From bPMLS a











GO
GRANT SELECT ON  [dbo].[PMLS] TO [public]
GRANT INSERT ON  [dbo].[PMLS] TO [public]
GRANT DELETE ON  [dbo].[PMLS] TO [public]
GRANT UPDATE ON  [dbo].[PMLS] TO [public]
GRANT SELECT ON  [dbo].[PMLS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMLS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMLS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMLS] TO [Viewpoint]
GO
