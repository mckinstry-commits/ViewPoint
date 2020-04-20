SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBL] as select a.* From bHRBL a

GO
GRANT SELECT ON  [dbo].[HRBL] TO [public]
GRANT INSERT ON  [dbo].[HRBL] TO [public]
GRANT DELETE ON  [dbo].[HRBL] TO [public]
GRANT UPDATE ON  [dbo].[HRBL] TO [public]
GO
