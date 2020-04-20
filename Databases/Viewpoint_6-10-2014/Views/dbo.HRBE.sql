SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBE] as select a.* From bHRBE a
GO
GRANT SELECT ON  [dbo].[HRBE] TO [public]
GRANT INSERT ON  [dbo].[HRBE] TO [public]
GRANT DELETE ON  [dbo].[HRBE] TO [public]
GRANT UPDATE ON  [dbo].[HRBE] TO [public]
GRANT SELECT ON  [dbo].[HRBE] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRBE] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRBE] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRBE] TO [Viewpoint]
GO
