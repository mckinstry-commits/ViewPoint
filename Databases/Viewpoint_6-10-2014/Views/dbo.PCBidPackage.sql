SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCBidPackage] as select a.* From vPCBidPackage a
GO
GRANT SELECT ON  [dbo].[PCBidPackage] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackage] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackage] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackage] TO [public]
GRANT SELECT ON  [dbo].[PCBidPackage] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCBidPackage] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCBidPackage] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCBidPackage] TO [Viewpoint]
GO
