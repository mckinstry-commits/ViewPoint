SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBD] as select a.* From bHRBD a
GO
GRANT SELECT ON  [dbo].[HRBD] TO [public]
GRANT INSERT ON  [dbo].[HRBD] TO [public]
GRANT DELETE ON  [dbo].[HRBD] TO [public]
GRANT UPDATE ON  [dbo].[HRBD] TO [public]
GRANT SELECT ON  [dbo].[HRBD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRBD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRBD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRBD] TO [Viewpoint]
GO
