SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRST] as select a.* From bHRST a
GO
GRANT SELECT ON  [dbo].[HRST] TO [public]
GRANT INSERT ON  [dbo].[HRST] TO [public]
GRANT DELETE ON  [dbo].[HRST] TO [public]
GRANT UPDATE ON  [dbo].[HRST] TO [public]
GRANT SELECT ON  [dbo].[HRST] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRST] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRST] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRST] TO [Viewpoint]
GO
