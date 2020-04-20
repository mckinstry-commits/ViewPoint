SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCO] as select a.* from bHQCO a 
GO
GRANT SELECT ON  [dbo].[HQCO] TO [public]
GRANT INSERT ON  [dbo].[HQCO] TO [public]
GRANT DELETE ON  [dbo].[HQCO] TO [public]
GRANT UPDATE ON  [dbo].[HQCO] TO [public]
GRANT SELECT ON  [dbo].[HQCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCO] TO [Viewpoint]
GO