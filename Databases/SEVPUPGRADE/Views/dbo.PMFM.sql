SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMFM] as select a.* From bPMFM a
GO
GRANT SELECT ON  [dbo].[PMFM] TO [public]
GRANT INSERT ON  [dbo].[PMFM] TO [public]
GRANT DELETE ON  [dbo].[PMFM] TO [public]
GRANT UPDATE ON  [dbo].[PMFM] TO [public]
GO
