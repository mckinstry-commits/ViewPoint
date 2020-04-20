SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRCB] as select a.* From bPRCB a

GO
GRANT SELECT ON  [dbo].[PRCB] TO [public]
GRANT INSERT ON  [dbo].[PRCB] TO [public]
GRANT DELETE ON  [dbo].[PRCB] TO [public]
GRANT UPDATE ON  [dbo].[PRCB] TO [public]
GO
