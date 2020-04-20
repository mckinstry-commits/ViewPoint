SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRLB] as select a.* From bPRLB a
GO
GRANT SELECT ON  [dbo].[PRLB] TO [public]
GRANT INSERT ON  [dbo].[PRLB] TO [public]
GRANT DELETE ON  [dbo].[PRLB] TO [public]
GRANT UPDATE ON  [dbo].[PRLB] TO [public]
GRANT SELECT ON  [dbo].[PRLB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRLB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRLB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRLB] TO [Viewpoint]
GO
