SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDC] as select a.* From bPMDC a

GO
GRANT SELECT ON  [dbo].[PMDC] TO [public]
GRANT INSERT ON  [dbo].[PMDC] TO [public]
GRANT DELETE ON  [dbo].[PMDC] TO [public]
GRANT UPDATE ON  [dbo].[PMDC] TO [public]
GO
