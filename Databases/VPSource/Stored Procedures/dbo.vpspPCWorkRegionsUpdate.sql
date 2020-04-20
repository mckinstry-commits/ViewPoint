SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCWorkRegionsUpdate]
	(@Original_KeyID BIGINT, @VendorGroup bGroup, @Vendor bVendor, @RegionCode VARCHAR(10), @WorkPrevious bPct, @WorkNext bPct, @NoPriorWork bYN)
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCWorkRegions
	SET
		VendorGroup = @VendorGroup,
		Vendor = @Vendor,
		RegionCode = @RegionCode,
		WorkPrevious = @WorkPrevious,
		WorkNext = @WorkNext,
		NoPriorWork = @NoPriorWork
	WHERE KeyID = @Original_KeyID
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCWorkRegionsUpdate] TO [VCSPortal]
GO
