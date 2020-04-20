SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMSM] as select a.* From bPMSM a
GO
GRANT SELECT ON  [dbo].[PMSM] TO [public]
GRANT INSERT ON  [dbo].[PMSM] TO [public]
GRANT DELETE ON  [dbo].[PMSM] TO [public]
GRANT UPDATE ON  [dbo].[PMSM] TO [public]
GRANT SELECT ON  [dbo].[PMSM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSM] TO [Viewpoint]
GO
