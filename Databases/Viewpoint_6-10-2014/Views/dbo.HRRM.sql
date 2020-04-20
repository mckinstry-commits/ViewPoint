SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRRM] as select a.* From bHRRM a
GO
GRANT SELECT ON  [dbo].[HRRM] TO [public]
GRANT INSERT ON  [dbo].[HRRM] TO [public]
GRANT DELETE ON  [dbo].[HRRM] TO [public]
GRANT UPDATE ON  [dbo].[HRRM] TO [public]
GRANT SELECT ON  [dbo].[HRRM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRRM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRRM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRRM] TO [Viewpoint]
GO
