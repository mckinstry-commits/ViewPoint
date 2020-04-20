SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCBidPackageScopes] as select a.* From vPCBidPackageScopes a
GO
GRANT SELECT ON  [dbo].[PCBidPackageScopes] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackageScopes] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackageScopes] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackageScopes] TO [public]
GO
