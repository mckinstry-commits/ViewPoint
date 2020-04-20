SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCProjectTypesInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @ProjectTypeCode VARCHAR(10), @WorkPrevious bPct, @WorkNext bPct, @NoPriorWork bYN)
AS
SET NOCOUNT ON;

BEGIN
	INSERT INTO PCProjectTypes
		(VendorGroup, Vendor, ProjectTypeCode, WorkPrevious, WorkNext, NoPriorWork)
	VALUES
		(@VendorGroup, @Vendor, @ProjectTypeCode, @WorkPrevious, @WorkNext, @NoPriorWork)
END
GO
GRANT EXECUTE ON  [dbo].[vpspPCProjectTypesInsert] TO [VCSPortal]
GO
