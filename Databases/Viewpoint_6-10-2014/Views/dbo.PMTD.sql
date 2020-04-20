SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTD] as select a.* From bPMTD a
GO
GRANT SELECT ON  [dbo].[PMTD] TO [public]
GRANT INSERT ON  [dbo].[PMTD] TO [public]
GRANT DELETE ON  [dbo].[PMTD] TO [public]
GRANT UPDATE ON  [dbo].[PMTD] TO [public]
GRANT SELECT ON  [dbo].[PMTD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMTD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMTD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMTD] TO [Viewpoint]
GO
