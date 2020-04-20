SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDT] as select a.* From bPMDT a
GO
GRANT SELECT ON  [dbo].[PMDT] TO [public]
GRANT INSERT ON  [dbo].[PMDT] TO [public]
GRANT DELETE ON  [dbo].[PMDT] TO [public]
GRANT UPDATE ON  [dbo].[PMDT] TO [public]
GO
