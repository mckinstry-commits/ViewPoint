SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HREH] as select a.* From bHREH a
GO
GRANT SELECT ON  [dbo].[HREH] TO [public]
GRANT INSERT ON  [dbo].[HREH] TO [public]
GRANT DELETE ON  [dbo].[HREH] TO [public]
GRANT UPDATE ON  [dbo].[HREH] TO [public]
GRANT SELECT ON  [dbo].[HREH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HREH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HREH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HREH] TO [Viewpoint]
GO
