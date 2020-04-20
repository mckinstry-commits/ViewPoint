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
GRANT SELECT ON  [dbo].[HQBC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQBC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQBC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQBC] TO [Viewpoint]
GO
