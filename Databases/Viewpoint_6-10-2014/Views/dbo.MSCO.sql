SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSCO] as select a.* From bMSCO a
GO
GRANT SELECT ON  [dbo].[MSCO] TO [public]
GRANT INSERT ON  [dbo].[MSCO] TO [public]
GRANT DELETE ON  [dbo].[MSCO] TO [public]
GRANT UPDATE ON  [dbo].[MSCO] TO [public]
GRANT SELECT ON  [dbo].[MSCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MSCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MSCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MSCO] TO [Viewpoint]
GO
