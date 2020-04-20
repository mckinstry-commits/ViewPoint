SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRI] as select a.* From bHRRI a
GO
GRANT SELECT ON  [dbo].[HRRI] TO [public]
GRANT INSERT ON  [dbo].[HRRI] TO [public]
GRANT DELETE ON  [dbo].[HRRI] TO [public]
GRANT UPDATE ON  [dbo].[HRRI] TO [public]
GRANT SELECT ON  [dbo].[HRRI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRI] TO [Viewpoint]
GO
