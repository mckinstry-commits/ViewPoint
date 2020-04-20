SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCRegionCodes] as select a.* From vPCRegionCodes a

GO
GRANT SELECT ON  [dbo].[PCRegionCodes] TO [public]
GRANT INSERT ON  [dbo].[PCRegionCodes] TO [public]
GRANT DELETE ON  [dbo].[PCRegionCodes] TO [public]
GRANT UPDATE ON  [dbo].[PCRegionCodes] TO [public]
GRANT SELECT ON  [dbo].[PCRegionCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCRegionCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCRegionCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCRegionCodes] TO [Viewpoint]
GO
