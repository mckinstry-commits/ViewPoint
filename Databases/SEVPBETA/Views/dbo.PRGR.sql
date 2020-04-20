SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRGR] as select a.* From bPRGR a

GO
GRANT SELECT ON  [dbo].[PRGR] TO [public]
GRANT INSERT ON  [dbo].[PRGR] TO [public]
GRANT DELETE ON  [dbo].[PRGR] TO [public]
GRANT UPDATE ON  [dbo].[PRGR] TO [public]
GO
