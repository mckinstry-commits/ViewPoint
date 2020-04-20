SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCR] as select a.* From bPRCR a
GO
GRANT SELECT ON  [dbo].[PRCR] TO [public]
GRANT INSERT ON  [dbo].[PRCR] TO [public]
GRANT DELETE ON  [dbo].[PRCR] TO [public]
GRANT UPDATE ON  [dbo].[PRCR] TO [public]
GO
