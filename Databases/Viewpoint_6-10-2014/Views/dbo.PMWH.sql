SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWH] as select a.* From bPMWH a
GO
GRANT SELECT ON  [dbo].[PMWH] TO [public]
GRANT INSERT ON  [dbo].[PMWH] TO [public]
GRANT DELETE ON  [dbo].[PMWH] TO [public]
GRANT UPDATE ON  [dbo].[PMWH] TO [public]
GRANT SELECT ON  [dbo].[PMWH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMWH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMWH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMWH] TO [Viewpoint]
GO
