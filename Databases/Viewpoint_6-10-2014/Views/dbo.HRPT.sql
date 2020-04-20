SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRPT] as select a.* From bHRPT a
GO
GRANT SELECT ON  [dbo].[HRPT] TO [public]
GRANT INSERT ON  [dbo].[HRPT] TO [public]
GRANT DELETE ON  [dbo].[HRPT] TO [public]
GRANT UPDATE ON  [dbo].[HRPT] TO [public]
GRANT SELECT ON  [dbo].[HRPT] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRPT] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRPT] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRPT] TO [Viewpoint]
GO
