SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOI] as select a.* From bPMOI a
GO
GRANT SELECT ON  [dbo].[PMOI] TO [public]
GRANT INSERT ON  [dbo].[PMOI] TO [public]
GRANT DELETE ON  [dbo].[PMOI] TO [public]
GRANT UPDATE ON  [dbo].[PMOI] TO [public]
GRANT SELECT ON  [dbo].[PMOI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOI] TO [Viewpoint]
GO
