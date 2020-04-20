SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 2/5/10
-- Description:	Updates the bid status of the contact.
-- =============================================
CREATE PROCEDURE [dbo].[vspPCBidPackageUpdateBidResponse]
	(@JCCo bCompany, @PotentialProject varchar(20), @BidPackage varchar(20), @VendorGroup bGroup, @Vendor bVendor, @ContactSeq AS tinyint, @BidResponse char(1), @DoMassUpdate bit)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @BidResponse = 'N' -- If the bid status is no response then we remove all the records for them. We have to use the table because the view doesn't allow deletes
	BEGIN
		DELETE FROM vPCBidCoverage
		WHERE JCCo = @JCCo AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND VendorGroup = @VendorGroup AND Vendor = @Vendor AND ContactSeq = @ContactSeq 
			AND (@DoMassUpdate = 1 OR BidResponse = 'N') --Either do the mass update or only delete that we just marked as no response on the last update
	END
	ELSE
	BEGIN
		--Insert any records that aren't exisiting yet
		INSERT PCBidCoverage (JCCo, PotentialProject, BidPackage, ScopePhaseSeq, VendorGroup, Vendor, ContactSeq)
		SELECT CoverageJCCo, CoveragePotentialProject, CoverageBidPackage, CoverageScopePhaseSeq, CoverageVendorGroup, CoverageVendor, CoverageContactSeq
		FROM PCBidCoverage
		WHERE ContactSeq IS NULL AND CoverageJCCo = @JCCo AND CoveragePotentialProject = @PotentialProject AND CoverageBidPackage = @BidPackage AND CoverageVendorGroup = @VendorGroup AND CoverageVendor = @Vendor AND CoverageContactSeq = @ContactSeq

		--Update the bid response for all the records
		UPDATE PCBidCoverage
		SET BidResponse = @BidResponse
		WHERE JCCo = @JCCo AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND VendorGroup = @VendorGroup AND Vendor = @Vendor AND ContactSeq = @ContactSeq
	END
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidPackageUpdateBidResponse] TO [public]
GO
