SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPL] as select a.* From bPMPL a
GO
GRANT SELECT ON  [dbo].[PMPL] TO [public]
GRANT INSERT ON  [dbo].[PMPL] TO [public]
GRANT DELETE ON  [dbo].[PMPL] TO [public]
GRANT UPDATE ON  [dbo].[PMPL] TO [public]
GO
