SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRPQ] as select a.* From bHRPQ a
GO
GRANT SELECT ON  [dbo].[HRPQ] TO [public]
GRANT INSERT ON  [dbo].[HRPQ] TO [public]
GRANT DELETE ON  [dbo].[HRPQ] TO [public]
GRANT UPDATE ON  [dbo].[HRPQ] TO [public]
GRANT SELECT ON  [dbo].[HRPQ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRPQ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRPQ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRPQ] TO [Viewpoint]
GO
