SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMEH] as select a.* From bPMEH a

GO
GRANT SELECT ON  [dbo].[PMEH] TO [public]
GRANT INSERT ON  [dbo].[PMEH] TO [public]
GRANT DELETE ON  [dbo].[PMEH] TO [public]
GRANT UPDATE ON  [dbo].[PMEH] TO [public]
GO
