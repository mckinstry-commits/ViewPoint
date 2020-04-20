SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCOwnersInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @Name VARCHAR(60), @Role VARCHAR(60), @BirthYear SMALLINT, @Ownership bPct)
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT
	IF not @BirthYear IS NULL
	BEGIN
		EXEC @rcode = vpspPCValidateYearField @BirthYear
		
		IF @rcode != 0
		BEGIN
			goto vpspExit
		END
	END
	
	-- Validation successful
	DECLARE @NextSeq TINYINT
	SELECT @NextSeq = ISNULL(MAX(Seq) + 1, 1) FROM PCOwners WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

	INSERT INTO PCOwners
		(VendorGroup, Vendor, Seq, Name, Role, BirthYear, Ownership)
	VALUES
		(@VendorGroup, @Vendor, @NextSeq, @Name, @Role, @BirthYear, @Ownership)

vpspExit:
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCOwnersInsert] TO [VCSPortal]
GO
