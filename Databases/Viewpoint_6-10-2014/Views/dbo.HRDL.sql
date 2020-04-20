SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRDL] as select a.* From bHRDL a
GO
GRANT SELECT ON  [dbo].[HRDL] TO [public]
GRANT INSERT ON  [dbo].[HRDL] TO [public]
GRANT DELETE ON  [dbo].[HRDL] TO [public]
GRANT UPDATE ON  [dbo].[HRDL] TO [public]
GRANT SELECT ON  [dbo].[HRDL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRDL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRDL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRDL] TO [Viewpoint]
GO
