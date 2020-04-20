SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMBE] as select a.* From bPMBE a
GO
GRANT SELECT ON  [dbo].[PMBE] TO [public]
GRANT INSERT ON  [dbo].[PMBE] TO [public]
GRANT DELETE ON  [dbo].[PMBE] TO [public]
GRANT UPDATE ON  [dbo].[PMBE] TO [public]
GRANT SELECT ON  [dbo].[PMBE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMBE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMBE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMBE] TO [Viewpoint]
GO
