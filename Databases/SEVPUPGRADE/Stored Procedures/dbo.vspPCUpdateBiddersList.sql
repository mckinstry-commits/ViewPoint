SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		CHS
-- Create date: 2/18/10
-- Description:	Adds a contact to a potential project's bidder list if not already added
-- =============================================
CREATE PROCEDURE [dbo].[vspPCUpdateBiddersList]
	(@JCCo bCompany, @PotentialProject VARCHAR(20), @BidPackage VARCHAR(20), @VendorGroup bGroup, @Vendor bVendor, @ContactSeq TINYINT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT TOP 1 1 FROM PCBidPackageBidList WHERE JCCo = @JCCo AND PotentialProject = @PotentialProject AND BidPackage = @BidPackage AND VendorGroup = @VendorGroup AND Vendor = @Vendor AND ContactSeq = @ContactSeq)
	BEGIN
		INSERT INTO PCBidPackageBidList (JCCo, PotentialProject, BidPackage, VendorGroup, Vendor, ContactSeq, AttendingWalkthrough, MessageStatus, LastSent)
		VALUES (@JCCo, @PotentialProject, @BidPackage, @VendorGroup, @Vendor, @ContactSeq, 'N', 'N', NULL) -- Default the walkthrough to no and the message status to not sent
    END
END


GO
GRANT EXECUTE ON  [dbo].[vspPCUpdateBiddersList] TO [public]
GO
