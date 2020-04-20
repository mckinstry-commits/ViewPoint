SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWD] as select a.* From bPMWD a

GO
GRANT SELECT ON  [dbo].[PMWD] TO [public]
GRANT INSERT ON  [dbo].[PMWD] TO [public]
GRANT DELETE ON  [dbo].[PMWD] TO [public]
GRANT UPDATE ON  [dbo].[PMWD] TO [public]
GO
