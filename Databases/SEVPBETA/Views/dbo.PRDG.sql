SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDG] as select a.* From bPRDG a

GO
GRANT SELECT ON  [dbo].[PRDG] TO [public]
GRANT INSERT ON  [dbo].[PRDG] TO [public]
GRANT DELETE ON  [dbo].[PRDG] TO [public]
GRANT UPDATE ON  [dbo].[PRDG] TO [public]
GO
