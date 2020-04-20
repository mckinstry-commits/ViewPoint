SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWI] as select a.* From bPMWI a
GO
GRANT SELECT ON  [dbo].[PMWI] TO [public]
GRANT INSERT ON  [dbo].[PMWI] TO [public]
GRANT DELETE ON  [dbo].[PMWI] TO [public]
GRANT UPDATE ON  [dbo].[PMWI] TO [public]
GRANT SELECT ON  [dbo].[PMWI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMWI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMWI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMWI] TO [Viewpoint]
GO
