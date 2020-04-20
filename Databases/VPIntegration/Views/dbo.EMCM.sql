SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMCM] as select a.* From bEMCM a
GO
GRANT SELECT ON  [dbo].[EMCM] TO [public]
GRANT INSERT ON  [dbo].[EMCM] TO [public]
GRANT DELETE ON  [dbo].[EMCM] TO [public]
GRANT UPDATE ON  [dbo].[EMCM] TO [public]
GO
