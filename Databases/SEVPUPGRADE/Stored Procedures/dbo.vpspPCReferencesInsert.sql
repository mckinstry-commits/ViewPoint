SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCReferencesInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @ReferenceTypeCode VARCHAR(10), @Contact VARCHAR(30), @Company VARCHAR(60), @Address VARCHAR(30), @City VARCHAR(30), @State VARCHAR(4), @Country CHAR(2), @Zip bZip, @Phone bPhone, @Fax bPhone, @Email VARCHAR(60), @Notes bNotes)
AS
SET NOCOUNT ON;

BEGIN
	DECLARE @NextSeq TINYINT
	SELECT @NextSeq = ISNULL(MAX(Seq) + 1, 1) FROM PCReferences WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

	INSERT INTO PCReferences
		(VendorGroup, Vendor, Seq, ReferenceTypeCode, Contact, Company, Address, City, State, Country, Zip, Phone, Fax, Email, Notes)
	VALUES
		(@VendorGroup, @Vendor, @NextSeq, @ReferenceTypeCode, @Contact, @Company, @Address, @City, @State, @Country, @Zip, @Phone, @Fax, @Email, @Notes)
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCReferencesInsert] TO [VCSPortal]
GO
