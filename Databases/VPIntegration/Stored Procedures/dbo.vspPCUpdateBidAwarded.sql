SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/26/10
-- Description:	Awards a bid package scope phase to someone in the same bid package
-- =============================================
CREATE PROCEDURE [dbo].[vspPCUpdateBidAwarded]
	@Company bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20), @ScopePhaseSeq BIGINT, @VendorGroup bGroup, @Vendor bVendor, @ContactSeq TINYINT, @BidAwarded bYN
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF @BidAwarded = 'Y'
    BEGIN
		--Set the awarded contact
		--If the scope/phase seq is null we award all scopes/phases for the bid package to the given contact
		UPDATE PCBidPackageScopes
		SET AwardedVendorGroup = @VendorGroup,
			AwardedVendor = @Vendor,
			AwardedContactSeq = @ContactSeq
		WHERE JCCo = @Company AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND Seq = ISNULL(@ScopePhaseSeq, Seq)
    END
    ELSE
    BEGIN
		-- Remove the awarded contact but only if it is the contact passed in
		-- This is also fired to set all the scopes/phases a contact has been awarded to null so that we can delete the contact. We can tell when it is being used in this case because
		-- the @ScopePhaseSeq will be null
		UPDATE PCBidPackageScopes
		SET AwardedVendorGroup = NULL,
			AwardedVendor = NULL,
			AwardedContactSeq = NULL
		WHERE JCCo = @Company AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND Seq = ISNULL(@ScopePhaseSeq, Seq) AND AwardedVendorGroup = @VendorGroup AND AwardedVendor = @Vendor AND AwardedContactSeq = @ContactSeq
    END
END

GO
GRANT EXECUTE ON  [dbo].[vspPCUpdateBidAwarded] TO [public]
GO
