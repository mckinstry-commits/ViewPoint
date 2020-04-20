SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCUnionContractsInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @LocalNumber VARCHAR(10), @Name VARCHAR(60), @Expiration bDate)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @NextSeq TINYINT
	SELECT @NextSeq = ISNULL(MAX(Seq) + 1, 1) FROM PCUnionContracts WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

	INSERT INTO PCUnionContracts
		(VendorGroup, Vendor, Seq, LocalNumber, Name, Expiration)
	VALUES
		(@VendorGroup, @Vendor, @NextSeq, @LocalNumber, @Name, @Expiration)
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCUnionContractsInsert] TO [VCSPortal]
GO
