SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOA] as select a.* From bPMOA a
GO
GRANT SELECT ON  [dbo].[PMOA] TO [public]
GRANT INSERT ON  [dbo].[PMOA] TO [public]
GRANT DELETE ON  [dbo].[PMOA] TO [public]
GRANT UPDATE ON  [dbo].[PMOA] TO [public]
GO
