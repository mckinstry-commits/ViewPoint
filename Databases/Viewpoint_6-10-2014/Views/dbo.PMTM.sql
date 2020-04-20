SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTM] as select a.* From bPMTM a
GO
GRANT SELECT ON  [dbo].[PMTM] TO [public]
GRANT INSERT ON  [dbo].[PMTM] TO [public]
GRANT DELETE ON  [dbo].[PMTM] TO [public]
GRANT UPDATE ON  [dbo].[PMTM] TO [public]
GRANT SELECT ON  [dbo].[PMTM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMTM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMTM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMTM] TO [Viewpoint]
GO
