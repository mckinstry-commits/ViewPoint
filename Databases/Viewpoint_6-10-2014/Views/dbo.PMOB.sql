SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOB] as select a.* From bPMOB a

GO
GRANT SELECT ON  [dbo].[PMOB] TO [public]
GRANT INSERT ON  [dbo].[PMOB] TO [public]
GRANT DELETE ON  [dbo].[PMOB] TO [public]
GRANT UPDATE ON  [dbo].[PMOB] TO [public]
GRANT SELECT ON  [dbo].[PMOB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOB] TO [Viewpoint]
GO
