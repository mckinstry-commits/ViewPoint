SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRHI] as select a.* From bHRHI a
GO
GRANT SELECT ON  [dbo].[HRHI] TO [public]
GRANT INSERT ON  [dbo].[HRHI] TO [public]
GRANT DELETE ON  [dbo].[HRHI] TO [public]
GRANT UPDATE ON  [dbo].[HRHI] TO [public]
GRANT SELECT ON  [dbo].[HRHI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRHI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRHI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRHI] TO [Viewpoint]
GO
