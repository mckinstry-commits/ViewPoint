SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTL] as select a.* from bPRTL a 
GO
GRANT SELECT ON  [dbo].[PRTL] TO [public]
GRANT INSERT ON  [dbo].[PRTL] TO [public]
GRANT DELETE ON  [dbo].[PRTL] TO [public]
GRANT UPDATE ON  [dbo].[PRTL] TO [public]
GO