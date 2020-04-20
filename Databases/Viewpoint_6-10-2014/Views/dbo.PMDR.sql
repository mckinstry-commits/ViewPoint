SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDR] as select a.* From bPMDR a
GO
GRANT SELECT ON  [dbo].[PMDR] TO [public]
GRANT INSERT ON  [dbo].[PMDR] TO [public]
GRANT DELETE ON  [dbo].[PMDR] TO [public]
GRANT UPDATE ON  [dbo].[PMDR] TO [public]
GRANT SELECT ON  [dbo].[PMDR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDR] TO [Viewpoint]
GO
