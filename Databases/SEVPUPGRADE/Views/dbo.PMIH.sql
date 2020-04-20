SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMIH] as select a.* From bPMIH a
GO
GRANT SELECT ON  [dbo].[PMIH] TO [public]
GRANT INSERT ON  [dbo].[PMIH] TO [public]
GRANT DELETE ON  [dbo].[PMIH] TO [public]
GRANT UPDATE ON  [dbo].[PMIH] TO [public]
GO
