SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTD] as select a.* From bPRTD a
GO
GRANT SELECT ON  [dbo].[PRTD] TO [public]
GRANT INSERT ON  [dbo].[PRTD] TO [public]
GRANT DELETE ON  [dbo].[PRTD] TO [public]
GRANT UPDATE ON  [dbo].[PRTD] TO [public]
GO
