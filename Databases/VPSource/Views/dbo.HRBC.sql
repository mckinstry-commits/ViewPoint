SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBC] as select a.* From bHRBC a

GO
GRANT SELECT ON  [dbo].[HRBC] TO [public]
GRANT INSERT ON  [dbo].[HRBC] TO [public]
GRANT DELETE ON  [dbo].[HRBC] TO [public]
GRANT UPDATE ON  [dbo].[HRBC] TO [public]
GO
