SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTL] as select a.* From bPMTL a
GO
GRANT SELECT ON  [dbo].[PMTL] TO [public]
GRANT INSERT ON  [dbo].[PMTL] TO [public]
GRANT DELETE ON  [dbo].[PMTL] TO [public]
GRANT UPDATE ON  [dbo].[PMTL] TO [public]
GRANT SELECT ON  [dbo].[PMTL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMTL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMTL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMTL] TO [Viewpoint]
GO
