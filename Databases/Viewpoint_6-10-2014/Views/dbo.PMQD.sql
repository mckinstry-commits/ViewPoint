SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMQD] as select a.* From bPMQD a
GO
GRANT SELECT ON  [dbo].[PMQD] TO [public]
GRANT INSERT ON  [dbo].[PMQD] TO [public]
GRANT DELETE ON  [dbo].[PMQD] TO [public]
GRANT UPDATE ON  [dbo].[PMQD] TO [public]
GRANT SELECT ON  [dbo].[PMQD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMQD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMQD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMQD] TO [Viewpoint]
GO
