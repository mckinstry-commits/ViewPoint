SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMEC] as select a.* From bPMEC a

GO
GRANT SELECT ON  [dbo].[PMEC] TO [public]
GRANT INSERT ON  [dbo].[PMEC] TO [public]
GRANT DELETE ON  [dbo].[PMEC] TO [public]
GRANT UPDATE ON  [dbo].[PMEC] TO [public]
GO
