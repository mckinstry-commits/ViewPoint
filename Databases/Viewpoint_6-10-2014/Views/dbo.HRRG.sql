SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRG] as select a.* From bHRRG a
GO
GRANT SELECT ON  [dbo].[HRRG] TO [public]
GRANT INSERT ON  [dbo].[HRRG] TO [public]
GRANT DELETE ON  [dbo].[HRRG] TO [public]
GRANT UPDATE ON  [dbo].[HRRG] TO [public]
GRANT SELECT ON  [dbo].[HRRG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRG] TO [Viewpoint]
GO
