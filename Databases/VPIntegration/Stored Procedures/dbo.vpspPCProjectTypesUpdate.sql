SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCProjectTypesUpdate]
	(@Original_KeyID BIGINT, @VendorGroup bGroup, @Vendor bVendor, @ProjectTypeCode VARCHAR(10), @WorkPrevious bPct, @WorkNext bPct, @NoPriorWork bYN)
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCProjectTypes
	SET
		VendorGroup = @VendorGroup,
		Vendor = @Vendor,
		ProjectTypeCode = @ProjectTypeCode,
		WorkPrevious = @WorkPrevious,
		WorkNext = @WorkNext,
		NoPriorWork = @NoPriorWork
	WHERE KeyID = @Original_KeyID
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCProjectTypesUpdate] TO [VCSPortal]
GO
