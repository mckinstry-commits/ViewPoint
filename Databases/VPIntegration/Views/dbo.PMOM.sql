SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOM] as select a.* From bPMOM a
GO
GRANT SELECT ON  [dbo].[PMOM] TO [public]
GRANT INSERT ON  [dbo].[PMOM] TO [public]
GRANT DELETE ON  [dbo].[PMOM] TO [public]
GRANT UPDATE ON  [dbo].[PMOM] TO [public]
GO
