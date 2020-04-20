SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUD] as select a.* From bPMUD a
GO
GRANT SELECT ON  [dbo].[PMUD] TO [public]
GRANT INSERT ON  [dbo].[PMUD] TO [public]
GRANT DELETE ON  [dbo].[PMUD] TO [public]
GRANT UPDATE ON  [dbo].[PMUD] TO [public]
GO
