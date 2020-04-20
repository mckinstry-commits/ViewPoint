SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMRD] as select a.* From bPMRD a
GO
GRANT SELECT ON  [dbo].[PMRD] TO [public]
GRANT INSERT ON  [dbo].[PMRD] TO [public]
GRANT DELETE ON  [dbo].[PMRD] TO [public]
GRANT UPDATE ON  [dbo].[PMRD] TO [public]
GO
