SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQBC] as select a.* From bHQBC a
GO
GRANT SELECT ON  [dbo].[HQBC] TO [public]
GRANT INSERT ON  [dbo].[HQBC] TO [public]
GRANT DELETE ON  [dbo].[HQBC] TO [public]
GRANT UPDATE ON  [dbo].[HQBC] TO [public]
GO
