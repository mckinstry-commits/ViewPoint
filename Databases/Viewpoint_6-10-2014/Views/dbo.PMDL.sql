SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDL] as select a.* From bPMDL a
GO
GRANT SELECT ON  [dbo].[PMDL] TO [public]
GRANT INSERT ON  [dbo].[PMDL] TO [public]
GRANT DELETE ON  [dbo].[PMDL] TO [public]
GRANT UPDATE ON  [dbo].[PMDL] TO [public]
GRANT SELECT ON  [dbo].[PMDL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDL] TO [Viewpoint]
GO
