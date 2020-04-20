SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMTH] as select a.* From bPMTH a

GO
GRANT SELECT ON  [dbo].[PMTH] TO [public]
GRANT INSERT ON  [dbo].[PMTH] TO [public]
GRANT DELETE ON  [dbo].[PMTH] TO [public]
GRANT UPDATE ON  [dbo].[PMTH] TO [public]
GO
