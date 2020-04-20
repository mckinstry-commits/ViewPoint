SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRDT] as select a.* From bHRDT a
GO
GRANT SELECT ON  [dbo].[HRDT] TO [public]
GRANT INSERT ON  [dbo].[HRDT] TO [public]
GRANT DELETE ON  [dbo].[HRDT] TO [public]
GRANT UPDATE ON  [dbo].[HRDT] TO [public]
GRANT SELECT ON  [dbo].[HRDT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRDT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRDT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRDT] TO [Viewpoint]
GO
