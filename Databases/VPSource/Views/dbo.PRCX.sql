SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCX] as select a.* From bPRCX a
GO
GRANT SELECT ON  [dbo].[PRCX] TO [public]
GRANT INSERT ON  [dbo].[PRCX] TO [public]
GRANT DELETE ON  [dbo].[PRCX] TO [public]
GRANT UPDATE ON  [dbo].[PRCX] TO [public]
GO
