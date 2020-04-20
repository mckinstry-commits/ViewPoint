SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[PCBidCoverage]  AS    SELECT vPCBidCoverage.*,    PCBidCoverageOverview.JCCo AS CoverageJCCo, PCBidCoverageOverview.PotentialProject AS CoveragePotentialProject,    PCBidCoverageOverview.BidPackage AS CoverageBidPackage, PCBidCoverageOverview.ScopePhaseSeq AS CoverageScopePhaseSeq,    PCBidCoverageOverview.ScopeCode AS CoverageScopeCode, PCBidCoverageOverview.PhaseGroup AS CoveragePhaseGroup,    PCBidCoverageOverview.Phase AS CoveragePhase, PCBidCoverageOverview.VendorGroup AS CoverageVendorGroup,    PCBidCoverageOverview.Vendor AS CoverageVendor, PCBidCoverageOverview.ContactSeq AS CoverageContactSeq,   PCBidCoverageOverview.AttendingWalkthrough, PCBidCoverageOverview.BidAwarded, PCBidCoverageOverview.MessageStatus,    PCBidCoverageOverview.LastSent  FROM dbo.vPCBidCoverage  RIGHT JOIN PCBidCoverageOverview WITH (NOLOCK) ON    vPCBidCoverage.JCCo = PCBidCoverageOverview.JCCo AND    vPCBidCoverage.PotentialProject = PCBidCoverageOverview.PotentialProject AND    vPCBidCoverage.BidPackage = PCBidCoverageOverview.BidPackage AND    vPCBidCoverage.ScopePhaseSeq = PCBidCoverageOverview.ScopePhaseSeq AND    vPCBidCoverage.VendorGroup = PCBidCoverageOverview.VendorGroup AND    vPCBidCoverage.Vendor = PCBidCoverageOverview.Vendor AND    vPCBidCoverage.ContactSeq = PCBidCoverageOverview.ContactSeq              

GO
GRANT SELECT ON  [dbo].[PCBidCoverage] TO [public]
GRANT INSERT ON  [dbo].[PCBidCoverage] TO [public]
GRANT DELETE ON  [dbo].[PCBidCoverage] TO [public]
GRANT UPDATE ON  [dbo].[PCBidCoverage] TO [public]
GO
