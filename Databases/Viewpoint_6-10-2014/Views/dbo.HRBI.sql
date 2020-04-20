SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRBI] as select a.* From bHRBI a
GO
GRANT SELECT ON  [dbo].[HRBI] TO [public]
GRANT INSERT ON  [dbo].[HRBI] TO [public]
GRANT DELETE ON  [dbo].[HRBI] TO [public]
GRANT UPDATE ON  [dbo].[HRBI] TO [public]
GRANT SELECT ON  [dbo].[HRBI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRBI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRBI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRBI] TO [Viewpoint]
GO
