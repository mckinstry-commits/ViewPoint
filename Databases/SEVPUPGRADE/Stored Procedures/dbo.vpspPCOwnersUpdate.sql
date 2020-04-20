SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCOwnersUpdate]
	(@Original_KeyID BIGINT, @VendorGroup bGroup, @Vendor bVendor, @Name VARCHAR(60), @Role VARCHAR(60), @BirthYear SMALLINT, @Ownership bPct)
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
	UPDATE PCOwners
	SET
		VendorGroup = @VendorGroup,
		Vendor = @Vendor,
		Name = @Name,
		Role = @Role,
		BirthYear = @BirthYear,
		Ownership = @Ownership
	WHERE KeyID = @Original_KeyID
	
vpspExit:
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCOwnersUpdate] TO [VCSPortal]
GO
