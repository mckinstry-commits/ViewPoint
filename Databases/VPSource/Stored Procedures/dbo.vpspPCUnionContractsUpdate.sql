SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCUnionContractsUpdate]
	(@Original_KeyID BIGINT, @VendorGroup bGroup, @Vendor bVendor, @LocalNumber VARCHAR(10), @Name VARCHAR(60), @Expiration bDate)
AS
SET NOCOUNT ON;

BEGIN
	UPDATE PCUnionContracts
	SET
		VendorGroup = @VendorGroup,
		Vendor = @Vendor,
		LocalNumber = @LocalNumber,
		Name = @Name,
		Expiration = @Expiration
	WHERE KeyID = @Original_KeyID
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCUnionContractsUpdate] TO [VCSPortal]
GO
