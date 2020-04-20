SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMMD] as select a.* From bPMMD a

GO
GRANT SELECT ON  [dbo].[PMMD] TO [public]
GRANT INSERT ON  [dbo].[PMMD] TO [public]
GRANT DELETE ON  [dbo].[PMMD] TO [public]
GRANT UPDATE ON  [dbo].[PMMD] TO [public]
GO
