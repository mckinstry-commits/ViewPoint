SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRFD] as select a.* From bPRFD a

GO
GRANT SELECT ON  [dbo].[PRFD] TO [public]
GRANT INSERT ON  [dbo].[PRFD] TO [public]
GRANT DELETE ON  [dbo].[PRFD] TO [public]
GRANT UPDATE ON  [dbo].[PRFD] TO [public]
GO
