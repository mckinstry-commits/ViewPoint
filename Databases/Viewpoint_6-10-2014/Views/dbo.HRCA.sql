SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCA] as select a.* From bHRCA a
GO
GRANT SELECT ON  [dbo].[HRCA] TO [public]
GRANT INSERT ON  [dbo].[HRCA] TO [public]
GRANT DELETE ON  [dbo].[HRCA] TO [public]
GRANT UPDATE ON  [dbo].[HRCA] TO [public]
GRANT SELECT ON  [dbo].[HRCA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRCA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRCA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRCA] TO [Viewpoint]
GO
