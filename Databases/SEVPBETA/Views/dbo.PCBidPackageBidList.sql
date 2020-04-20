SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PCBidPackageBidList] as select a.* From vPCBidPackageBidList a
GO
GRANT SELECT ON  [dbo].[PCBidPackageBidList] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackageBidList] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackageBidList] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackageBidList] TO [public]
GO
