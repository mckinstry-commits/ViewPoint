SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[PCBidCoverageOverview]
AS

SELECT DISTINCT PCBidPackageScopes.JCCo, PCBidPackageScopes.PotentialProject, PCBidPackageScopes.BidPackage, 
	PCBidPackageScopes.Seq AS ScopePhaseSeq, PCBidPackageScopes.ScopeCode, PCBidPackageScopes.PhaseGroup, 
	PCBidPackageScopes.Phase, PCBidPackageBidList.VendorGroup, PCBidPackageBidList.Vendor, 
	PCBidPackageBidList.ContactSeq, PCBidPackageBidList.AttendingWalkthrough, 
	ISNULL(PCBidPackageBidList.MessageStatus, 'N') AS MessageStatus, PCBidPackageBidList.LastSent,
	CASE WHEN 
		PCBidPackageBidList.VendorGroup = PCBidPackageScopes.AwardedVendorGroup 
		AND PCBidPackageBidList.Vendor = PCBidPackageScopes.AwardedVendor 
		AND PCBidPackageBidList.ContactSeq = PCBidPackageScopes.AwardedContactSeq 
		THEN 'Y' ELSE 'N' END AS BidAwarded
FROM dbo.PCBidPackageScopes
INNER JOIN dbo.PCBidPackageBidList 
	ON PCBidPackageScopes.JCCo = PCBidPackageBidList.JCCo 
	AND PCBidPackageScopes.PotentialProject = PCBidPackageBidList.PotentialProject 
	AND PCBidPackageScopes.BidPackage = PCBidPackageBidList.BidPackage
LEFT JOIN PCScopes 
	ON dbo.PCBidPackageBidList.VendorGroup = dbo.PCScopes.VendorGroup
	AND dbo.PCBidPackageBidList.Vendor = dbo.PCScopes.Vendor
	AND 
	(
		dbo.PCBidPackageScopes.ScopeCode = dbo.PCScopes.ScopeCode
		OR dbo.PCBidPackageScopes.Phase = dbo.PCScopes.PhaseCode
	)

WHERE 	(PCScopes.KeyID IS NOT NULL 
		 OR NOT EXISTS (	SELECT 1
					FROM PCScopes 
					WHERE dbo.PCBidPackageBidList.VendorGroup = dbo.PCScopes.VendorGroup 
					AND dbo.PCBidPackageBidList.Vendor = dbo.PCScopes.Vendor
				)
		)


GO
GRANT SELECT ON  [dbo].[PCBidCoverageOverview] TO [public]
GRANT INSERT ON  [dbo].[PCBidCoverageOverview] TO [public]
GRANT DELETE ON  [dbo].[PCBidCoverageOverview] TO [public]
GRANT UPDATE ON  [dbo].[PCBidCoverageOverview] TO [public]
GRANT SELECT ON  [dbo].[PCBidCoverageOverview] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCBidCoverageOverview] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCBidCoverageOverview] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCBidCoverageOverview] TO [Viewpoint]
GO
