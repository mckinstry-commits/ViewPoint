SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOH] as select a.* From bPMOH a
GO
GRANT SELECT ON  [dbo].[PMOH] TO [public]
GRANT INSERT ON  [dbo].[PMOH] TO [public]
GRANT DELETE ON  [dbo].[PMOH] TO [public]
GRANT UPDATE ON  [dbo].[PMOH] TO [public]
GO
