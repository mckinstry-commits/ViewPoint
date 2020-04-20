SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCWorkRegionsInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @RegionCode VARCHAR(10), @WorkPrevious bPct, @WorkNext bPct, @NoPriorWork bYN)
AS
SET NOCOUNT ON;

BEGIN
	INSERT INTO PCWorkRegions
		(VendorGroup, Vendor, RegionCode, WorkPrevious, WorkNext, NoPriorWork)
	VALUES
		(@VendorGroup, @Vendor, @RegionCode, @WorkPrevious, @WorkNext, @NoPriorWork)
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCWorkRegionsInsert] TO [VCSPortal]
GO
