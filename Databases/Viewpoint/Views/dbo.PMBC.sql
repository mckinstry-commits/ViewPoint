SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMBC] as select a.* From bPMBC a

GO
GRANT SELECT ON  [dbo].[PMBC] TO [public]
GRANT INSERT ON  [dbo].[PMBC] TO [public]
GRANT DELETE ON  [dbo].[PMBC] TO [public]
GRANT UPDATE ON  [dbo].[PMBC] TO [public]
GO
