SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTS] as select a.* From bPMTS a
GO
GRANT SELECT ON  [dbo].[PMTS] TO [public]
GRANT INSERT ON  [dbo].[PMTS] TO [public]
GRANT DELETE ON  [dbo].[PMTS] TO [public]
GRANT UPDATE ON  [dbo].[PMTS] TO [public]
GRANT SELECT ON  [dbo].[PMTS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMTS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMTS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMTS] TO [Viewpoint]
GO
