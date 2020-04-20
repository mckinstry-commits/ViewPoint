SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMCO] as select a.* From bPMCO a

GO
GRANT SELECT ON  [dbo].[PMCO] TO [public]
GRANT INSERT ON  [dbo].[PMCO] TO [public]
GRANT DELETE ON  [dbo].[PMCO] TO [public]
GRANT UPDATE ON  [dbo].[PMCO] TO [public]
GO
