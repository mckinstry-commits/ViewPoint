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
GO
