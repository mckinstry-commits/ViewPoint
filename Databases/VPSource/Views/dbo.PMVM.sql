SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMVM] as select a.* From bPMVM a

GO
GRANT SELECT ON  [dbo].[PMVM] TO [public]
GRANT INSERT ON  [dbo].[PMVM] TO [public]
GRANT DELETE ON  [dbo].[PMVM] TO [public]
GRANT UPDATE ON  [dbo].[PMVM] TO [public]
GO
