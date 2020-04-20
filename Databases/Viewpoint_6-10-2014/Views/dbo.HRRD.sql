SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRD] as select a.* From bHRRD a
GO
GRANT SELECT ON  [dbo].[HRRD] TO [public]
GRANT INSERT ON  [dbo].[HRRD] TO [public]
GRANT DELETE ON  [dbo].[HRRD] TO [public]
GRANT UPDATE ON  [dbo].[HRRD] TO [public]
GRANT SELECT ON  [dbo].[HRRD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRD] TO [Viewpoint]
GO
