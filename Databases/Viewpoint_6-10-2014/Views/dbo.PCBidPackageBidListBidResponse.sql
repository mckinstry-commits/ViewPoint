SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[PCBidPackageBidListBidResponse]
AS

SELECT PCBidPackageBidList.JCCo, PCBidPackageBidList.PotentialProject, PCBidPackageBidList.BidPackage, PCBidPackageBidList.VendorGroup, PCBidPackageBidList.Vendor, PCBidPackageBidList.ContactSeq, ISNULL(BidResponseQuery.BidResponse, 'N') AS BidResponse
FROM PCBidPackageBidList
	LEFT JOIN (SELECT JCCo, PotentialProject, BidPackage, VendorGroup, Vendor, ContactSeq, 
	--Rules for BidResponse rollup. If at least one record exists for a contact on a bid package then that response will be reported.
	--The order we look for the records is in this order Will Bid, Declined, Undecided, No Response
	CASE WHEN COUNT(CASE WHEN BidResponse = 'W' THEN 1 ELSE NULL END) > 0 THEN 'W' WHEN COUNT(CASE WHEN BidResponse = 'U' THEN 1 ELSE NULL END) > 0 THEN 'U' WHEN COUNT(CASE WHEN BidResponse = 'D' THEN 1 ELSE NULL END) > 0 THEN 'D' ELSE 'N' END AS BidResponse
				FROM vPCBidCoverage
				GROUP BY JCCo, PotentialProject, BidPackage, VendorGroup, Vendor, ContactSeq) BidResponseQuery 
		ON PCBidPackageBidList.JCCo = BidResponseQuery.JCCo AND PCBidPackageBidList.PotentialProject = BidResponseQuery.PotentialProject AND PCBidPackageBidList.BidPackage = BidResponseQuery.BidPackage AND PCBidPackageBidList.VendorGroup = BidResponseQuery.VendorGroup AND PCBidPackageBidList.Vendor = BidResponseQuery.Vendor AND PCBidPackageBidList.ContactSeq = BidResponseQuery.ContactSeq






GO
GRANT SELECT ON  [dbo].[PCBidPackageBidListBidResponse] TO [public]
GRANT INSERT ON  [dbo].[PCBidPackageBidListBidResponse] TO [public]
GRANT DELETE ON  [dbo].[PCBidPackageBidListBidResponse] TO [public]
GRANT UPDATE ON  [dbo].[PCBidPackageBidListBidResponse] TO [public]
GRANT SELECT ON  [dbo].[PCBidPackageBidListBidResponse] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCBidPackageBidListBidResponse] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCBidPackageBidListBidResponse] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCBidPackageBidListBidResponse] TO [Viewpoint]
GO
