SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGV] as select a.* From bPRGV a

GO
GRANT SELECT ON  [dbo].[PRGV] TO [public]
GRANT INSERT ON  [dbo].[PRGV] TO [public]
GRANT DELETE ON  [dbo].[PRGV] TO [public]
GRANT UPDATE ON  [dbo].[PRGV] TO [public]
GO
