SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUX] as select a.* From bPMUX a

GO
GRANT SELECT ON  [dbo].[PMUX] TO [public]
GRANT INSERT ON  [dbo].[PMUX] TO [public]
GRANT DELETE ON  [dbo].[PMUX] TO [public]
GRANT UPDATE ON  [dbo].[PMUX] TO [public]
GO
