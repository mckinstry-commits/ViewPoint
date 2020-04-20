SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDD] as select a.* From bPMDD a

GO
GRANT SELECT ON  [dbo].[PMDD] TO [public]
GRANT INSERT ON  [dbo].[PMDD] TO [public]
GRANT DELETE ON  [dbo].[PMDD] TO [public]
GRANT UPDATE ON  [dbo].[PMDD] TO [public]
GO
