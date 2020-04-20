SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMRI] as select a.* From bPMRI a
GO
GRANT SELECT ON  [dbo].[PMRI] TO [public]
GRANT INSERT ON  [dbo].[PMRI] TO [public]
GRANT DELETE ON  [dbo].[PMRI] TO [public]
GRANT UPDATE ON  [dbo].[PMRI] TO [public]
GO
