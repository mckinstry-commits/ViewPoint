SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWP] as select a.* From bPMWP a

GO
GRANT SELECT ON  [dbo].[PMWP] TO [public]
GRANT INSERT ON  [dbo].[PMWP] TO [public]
GRANT DELETE ON  [dbo].[PMWP] TO [public]
GRANT UPDATE ON  [dbo].[PMWP] TO [public]
GO
