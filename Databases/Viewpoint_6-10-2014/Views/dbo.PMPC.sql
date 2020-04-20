SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPC] as select a.* From bPMPC a
GO
GRANT SELECT ON  [dbo].[PMPC] TO [public]
GRANT INSERT ON  [dbo].[PMPC] TO [public]
GRANT DELETE ON  [dbo].[PMPC] TO [public]
GRANT UPDATE ON  [dbo].[PMPC] TO [public]
GRANT SELECT ON  [dbo].[PMPC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMPC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMPC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMPC] TO [Viewpoint]
GO
