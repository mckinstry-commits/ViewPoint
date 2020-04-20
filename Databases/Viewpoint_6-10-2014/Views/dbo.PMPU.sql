SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPU] as select a.* From bPMPU a
GO
GRANT SELECT ON  [dbo].[PMPU] TO [public]
GRANT INSERT ON  [dbo].[PMPU] TO [public]
GRANT DELETE ON  [dbo].[PMPU] TO [public]
GRANT UPDATE ON  [dbo].[PMPU] TO [public]
GRANT SELECT ON  [dbo].[PMPU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPU] TO [Viewpoint]
GO
