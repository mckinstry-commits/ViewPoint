SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRC] as select a.* From bHRRC a
GO
GRANT SELECT ON  [dbo].[HRRC] TO [public]
GRANT INSERT ON  [dbo].[HRRC] TO [public]
GRANT DELETE ON  [dbo].[HRRC] TO [public]
GRANT UPDATE ON  [dbo].[HRRC] TO [public]
GRANT SELECT ON  [dbo].[HRRC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRC] TO [Viewpoint]
GO
