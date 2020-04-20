SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/26/10
-- Description:	Validation to check if a ScopePhase has already been awarded to some one else
-- =============================================
CREATE PROCEDURE [dbo].[vspPCBidAwardedValidation]
	@Company bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20), @ScopePhaseSeq BIGINT, @VendorGroup bGroup, @Vendor bVendor, @ContactSeq TINYINT, @BidAwarded bYN, @msg VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @BidAwarded = 'Y' AND EXISTS (SELECT TOP 1 1 FROM PCBidPackageScopes WHERE JCCo = @Company AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND Seq = @ScopePhaseSeq AND NOT (AwardedVendorGroup = @VendorGroup AND AwardedVendor = @Vendor AND AwardedContactSeq = @ContactSeq))
	BEGIN
		SELECT @msg = 'This scope or phase has already been awarded to ' + ISNULL(PCContacts.Name, '') + ' from ' + ISNULL(PCQualifications.Name, '') + '. Saving will override who is awarded the scope/phase.'
		FROM PCBidPackageScopes
			LEFT JOIN PCQualifications ON PCBidPackageScopes.AwardedVendorGroup = PCQualifications.VendorGroup AND PCBidPackageScopes.AwardedVendor = PCQualifications.Vendor
			LEFT JOIN PCContacts ON PCBidPackageScopes.AwardedVendorGroup = PCContacts.VendorGroup AND PCBidPackageScopes.AwardedVendor = PCContacts.Vendor AND PCBidPackageScopes.AwardedContactSeq = PCContacts.Seq
		WHERE PCBidPackageScopes.JCCo = @Company AND PCBidPackageScopes.PotentialProject = @PotentialProject AND PCBidPackageScopes.BidPackage = @BidPackage AND PCBidPackageScopes.Seq = @ScopePhaseSeq
		
		RETURN 1
	END
	ELSE
	BEGIN
		RETURN 0
	END
	
END

GO
GRANT EXECUTE ON  [dbo].[vspPCBidAwardedValidation] TO [public]
GO
