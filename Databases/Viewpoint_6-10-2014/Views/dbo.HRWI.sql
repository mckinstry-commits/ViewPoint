SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRWI] as select a.* From bHRWI a
GO
GRANT SELECT ON  [dbo].[HRWI] TO [public]
GRANT INSERT ON  [dbo].[HRWI] TO [public]
GRANT DELETE ON  [dbo].[HRWI] TO [public]
GRANT UPDATE ON  [dbo].[HRWI] TO [public]
GRANT SELECT ON  [dbo].[HRWI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRWI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRWI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRWI] TO [Viewpoint]
GO
